"""
services/vector_store_service.py
─────────────────────────────────────────────────────────
역할: Chroma DB에 문서 저장 / 유사 문서 검색

Chroma DB 개념:
  - Collection: 관계형 DB의 테이블과 같음
  - Document: 저장할 텍스트 (청크 단위)
  - Embedding: 문서의 벡터 표현
  - Metadata: 출처 파일명, 페이지 번호 등 부가 정보
  - ID: 각 청크의 고유 식별자

검색 원리:
  1. 질문 → 벡터 변환
  2. Chroma DB에서 코사인 유사도로 가까운 벡터 찾기
  3. 해당 벡터의 원본 텍스트(Document) 반환
"""

import uuid
import chromadb
from chromadb.config import Settings
from typing import List, Dict, Any
from config import config
from services.embedding_service import embedding_service


class VectorStoreService:

    def __init__(self):
        # ── Chroma 클라이언트 초기화 ──────────────────
        # PersistentClient: 디스크에 저장 (서버 재시작해도 데이터 유지)
        # EphemeralClient: 메모리에만 저장 (테스트용)
        self.client = chromadb.PersistentClient(
            path=config.CHROMA_PERSIST_DIR,
            settings=Settings(anonymized_telemetry=False)  # 텔레메트리 비활성화
        )

        # 컬렉션 가져오기 (없으면 생성)
        # get_or_create_collection = Spring의 findOrCreate 패턴
        self.collection = self.client.get_or_create_collection(
            name=config.COLLECTION_NAME,
            # 거리 계산 방식: cosine = 방향 유사도 (텍스트에 적합)
            # l2 = 유클리드 거리, ip = 내적
            metadata={"hnsw:space": "cosine"}
        )
        print(f"Chroma DB 초기화 완료. 저장된 문서 수: {self.collection.count()}")

    # ─────────────────────────────────────────────
    # 문서 저장
    # ─────────────────────────────────────────────

    def add_documents(
        self,
        texts: List[str],
        metadatas: List[Dict[str, Any]],
        ids: List[str] = None
    ) -> int:
        """
        청크 텍스트들을 벡터로 변환 후 Chroma에 저장

        Args:
            texts:     ["청크1 내용", "청크2 내용", ...]
            metadatas: [{"source": "파일명.pdf", "page": 1}, ...]
            ids:       고유 ID (없으면 UUID 자동 생성)

        Returns:
            저장된 문서 수
        """
        if not texts:
            return 0

        # ID 자동 생성
        if ids is None:
            ids = [str(uuid.uuid4()) for _ in texts]

        # 텍스트 → 벡터 변환 (배치 처리)
        print(f"임베딩 생성 중... ({len(texts)}개 청크)")
        embeddings = embedding_service.embed_texts(texts)

        # Chroma에 저장
        # upsert = 이미 있으면 업데이트, 없으면 삽입 (Spring의 save()와 유사)
        self.collection.upsert(
            ids=ids,
            documents=texts,
            embeddings=embeddings,
            metadatas=metadatas
        )

        print(f"저장 완료. 전체 문서 수: {self.collection.count()}")
        return len(texts)

    # ─────────────────────────────────────────────
    # 유사 문서 검색
    # ─────────────────────────────────────────────

    def search(
        self,
        query: str,
        top_k: int = None,
        filter_metadata: Dict = None
    ) -> List[Dict[str, Any]]:
        """
        질문과 가장 유사한 문서 청크들을 반환

        Args:
            query:           "사용자 질문"
            top_k:           몇 개 반환할지 (기본값: config.TOP_K)
            filter_metadata: 특정 파일만 검색 {"source": "파일명.pdf"}

        Returns:
            [
                {
                    "text": "관련 문서 내용",
                    "source": "파일명.pdf",
                    "score": 0.87,   ← 유사도 (1에 가까울수록 관련성 높음)
                    "page": 3
                },
                ...
            ]
        """
        if top_k is None:
            top_k = config.TOP_K

        # 저장된 문서가 없으면 빈 결과 반환
        if self.collection.count() == 0:
            return []

        # 질문 → 벡터 변환
        query_embedding = embedding_service.embed_query(query)

        # 벡터 유사도 검색
        results = self.collection.query(
            query_embeddings=[query_embedding],
            n_results=min(top_k, self.collection.count()),  # 저장된 것보다 많이 요청 방지
            where=filter_metadata,  # None이면 전체 검색
            include=["documents", "metadatas", "distances"]
        )

        # 결과 정리
        docs = []
        for i, (text, meta, dist) in enumerate(zip(
            results["documents"][0],
            results["metadatas"][0],
            results["distances"][0]
        )):
            # cosine 거리 → 유사도 변환 (거리 0 = 완전 동일 → 유사도 1.0)
            similarity = 1 - dist

            docs.append({
                "text": text,
                "source": meta.get("source", "알 수 없음"),
                "page": meta.get("page", 0),
                "chunk_index": meta.get("chunk_index", i),
                "score": round(similarity, 4)
            })

        return docs

    def get_document_count(self) -> int:
        """저장된 전체 청크 수 반환"""
        return self.collection.count()

    def delete_by_source(self, source: str) -> int:
        """특정 파일의 모든 청크 삭제"""
        results = self.collection.get(
            where={"source": source},
            include=[]
        )
        ids = results["ids"]
        if ids:
            self.collection.delete(ids=ids)
        return len(ids)

    def list_sources(self) -> List[str]:
        """인덱싱된 파일 목록 반환"""
        if self.collection.count() == 0:
            return []
        results = self.collection.get(include=["metadatas"])
        sources = {m.get("source", "") for m in results["metadatas"]}
        return sorted(list(sources))


# 싱글턴 인스턴스
vector_store = VectorStoreService()
