"""
services/document_service.py
─────────────────────────────────────────────────────────
역할: 다양한 소스(PDF, DB)에서 텍스트를 읽어 청크로 분할 후 Chroma에 저장

청킹(Chunking) 개념:
  긴 문서를 그대로 저장하면 검색 정확도가 떨어짐
  → 일정 크기(예: 500자)로 잘라서 각각 벡터화해서 저장

  예시: 10페이지 PDF
    → 청크1: 1페이지 1~500자
    → 청크2: 1페이지 450~950자  (overlap=50자 겹침으로 문맥 유지)
    → 청크3: ...
    → 총 30개 청크로 Chroma에 저장
"""

import re
import uuid
from typing import List, Dict, Any, Tuple
from pathlib import Path

from config import config
from services.vector_store_service import vector_store


class DocumentService:

    # ─────────────────────────────────────────────
    # PDF 처리
    # ─────────────────────────────────────────────

    def index_pdf(self, file_path: str, file_name: str) -> Dict[str, Any]:
        """
        PDF 파일을 읽어서 Chroma DB에 인덱싱

        Args:
            file_path: 저장된 파일의 실제 경로
            file_name: 표시할 파일 이름 (출처로 사용)

        Returns:
            {"chunks": 30, "pages": 10, "source": "파일명.pdf"}
        """
        # 1단계: PDF에서 페이지별 텍스트 추출
        pages = self._extract_pdf_pages(file_path)

        if not pages:
            raise ValueError("PDF에서 텍스트를 추출할 수 없습니다. (스캔 이미지 PDF는 지원 안 함)")

        # 2단계: 텍스트를 청크로 분할
        chunks, metadatas = self._chunk_pages(pages, file_name)

        # 3단계: 기존 같은 파일 데이터 삭제 (재인덱싱)
        deleted = vector_store.delete_by_source(file_name)
        if deleted > 0:
            print(f"기존 데이터 {deleted}개 삭제 후 재인덱싱")

        # 4단계: Chroma에 저장
        count = vector_store.add_documents(chunks, metadatas)

        return {
            "chunks": count,
            "pages": len(pages),
            "source": file_name,
            "message": f"'{file_name}' 인덱싱 완료 ({count}개 청크)"
        }

    def _extract_pdf_pages(self, file_path: str) -> List[Tuple[int, str]]:
        """
        PDF 각 페이지에서 텍스트 추출

        Returns:
            [(페이지번호, 텍스트), (2, "..."), ...]
        """
        from pypdf import PdfReader

        reader = PdfReader(file_path)
        pages = []

        for i, page in enumerate(reader.pages, start=1):
            text = page.extract_text() or ""
            # 불필요한 공백 정리
            text = re.sub(r'\s+', ' ', text).strip()
            if text:  # 빈 페이지 제외
                pages.append((i, text))

        return pages

    def _chunk_pages(
        self,
        pages: List[Tuple[int, str]],
        source: str
    ) -> Tuple[List[str], List[Dict]]:
        """
        페이지 텍스트를 청크로 분할

        슬라이딩 윈도우 방식:
          [===청크1===]
               [===청크2===]  ← overlap만큼 겹침
                    [===청크3===]

        Args:
            pages:  [(1, "페이지1 텍스트"), (2, "페이지2 텍스트"), ...]
            source: "파일명.pdf"

        Returns:
            (청크 텍스트 리스트, 메타데이터 리스트)
        """
        chunks = []
        metadatas = []
        chunk_index = 0

        for page_num, text in pages:
            # 페이지 텍스트를 CHUNK_SIZE 단위로 분할
            start = 0
            while start < len(text):
                end = start + config.CHUNK_SIZE
                chunk = text[start:end].strip()

                if len(chunk) > 50:  # 너무 짧은 청크 제외
                    chunks.append(chunk)
                    metadatas.append({
                        "source": source,
                        "page": page_num,
                        "chunk_index": chunk_index
                    })
                    chunk_index += 1

                # 다음 청크 시작: overlap만큼 뒤로 당겨서 문맥 연속성 유지
                start = end - config.CHUNK_OVERLAP
                if start >= len(text):
                    break

        return chunks, metadatas

    # ─────────────────────────────────────────────
    # DB 데이터 처리
    # ─────────────────────────────────────────────

    def index_db_table(
        self,
        table_name: str,
        text_columns: List[str],
        id_column: str = "id",
        batch_size: int = 100
    ) -> Dict[str, Any]:
        """
        MySQL 테이블의 데이터를 Chroma에 인덱싱

        사용 예시:
          # products 테이블의 name, description 컬럼을 RAG 소스로 사용
          index_db_table("products", ["name", "description"])

        Args:
            table_name:   인덱싱할 테이블명
            text_columns: 텍스트로 저장할 컬럼명들
            id_column:    고유 ID 컬럼명 (기본: "id")
            batch_size:   한 번에 처리할 행 수

        Returns:
            {"rows": 500, "chunks": 500, "source": "db:products"}
        """
        from sqlalchemy import create_engine, text

        source_name = f"db:{table_name}"

        # DB 연결
        engine = create_engine(config.DB_URL)

        chunks = []
        metadatas = []
        row_count = 0

        with engine.connect() as conn:
            # 컬럼 목록을 SQL에 안전하게 삽입 (SQL 인젝션 방지: 컬럼명은 직접 삽입)
            col_list = ", ".join([id_column] + text_columns)
            rows = conn.execute(text(f"SELECT {col_list} FROM {table_name}"))

            for row in rows:
                row_id = str(row[0])

                # 여러 컬럼을 하나의 텍스트로 합치기
                # 예: "상품명: 에어컨\n설명: 냉방 효율이 뛰어난..."
                parts = []
                for i, col in enumerate(text_columns, start=1):
                    val = str(row[i]) if row[i] else ""
                    if val.strip():
                        parts.append(f"{col}: {val}")

                combined_text = "\n".join(parts)

                if combined_text.strip():
                    chunks.append(combined_text)
                    metadatas.append({
                        "source": source_name,
                        "row_id": row_id,
                        "table": table_name,
                        "chunk_index": row_count
                    })
                    row_count += 1

                # 배치 단위로 저장 (메모리 효율)
                if len(chunks) >= batch_size:
                    vector_store.delete_by_source(source_name)
                    vector_store.add_documents(chunks, metadatas)
                    chunks = []
                    metadatas = []

        # 나머지 저장
        if chunks:
            vector_store.add_documents(chunks, metadatas)

        return {
            "rows": row_count,
            "chunks": row_count,
            "source": source_name,
            "message": f"'{table_name}' 테이블 인덱싱 완료 ({row_count}행)"
        }


# 싱글턴 인스턴스
document_service = DocumentService()
