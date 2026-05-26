"""
routers/document_router.py
─────────────────────────────────────────────────────────
역할: 문서 업로드 / DB 인덱싱 / 상태 조회 엔드포인트
"""

import os
import tempfile
from fastapi import APIRouter, UploadFile, File, HTTPException
from models.schemas import (
    DbIndexRequest, IndexResponse, StatusResponse,
    SearchRequest, SearchResult
)
from services.document_service import document_service
from services.vector_store_service import vector_store
from config import config
from typing import List

router = APIRouter(prefix="/documents", tags=["documents"])


@router.post("/upload-pdf", response_model=IndexResponse)
async def upload_pdf(file: UploadFile = File(...)):
    """
    PDF 파일 업로드 후 Chroma DB에 인덱싱
    POST /documents/upload-pdf

    Spring Boot가 PDF를 멀티파트 폼으로 전송하면
    이 엔드포인트에서 받아서 처리
    """
    # 파일 확장자 검증
    if not file.filename.endswith(".pdf"):
        raise HTTPException(status_code=400, detail="PDF 파일만 업로드 가능합니다")

    # 임시 파일에 저장 (처리 후 자동 삭제)
    with tempfile.NamedTemporaryFile(delete=False, suffix=".pdf") as tmp:
        content = await file.read()
        tmp.write(content)
        tmp_path = tmp.name

    try:
        result = document_service.index_pdf(tmp_path, file.filename)
        return IndexResponse(
            message=result["message"],
            chunks=result["chunks"],
            source=result["source"]
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"인덱싱 실패: {str(e)}")
    finally:
        # 임시 파일 삭제
        os.unlink(tmp_path)


@router.post("/index-db", response_model=IndexResponse)
async def index_db_table(request: DbIndexRequest):
    """
    MySQL 테이블 데이터를 Chroma DB에 인덱싱
    POST /documents/index-db

    요청 예시:
      {
        "table_name": "products",
        "text_columns": ["name", "description", "category"],
        "id_column": "id"
      }
    """
    try:
        result = document_service.index_db_table(
            table_name=request.table_name,
            text_columns=request.text_columns,
            id_column=request.id_column
        )
        return IndexResponse(
            message=result["message"],
            chunks=result["chunks"],
            source=result["source"]
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"DB 인덱싱 실패: {str(e)}")


@router.delete("/{source}")
async def delete_source(source: str):
    """
    특정 소스의 인덱스 삭제
    DELETE /documents/{source}
    """
    deleted = vector_store.delete_by_source(source)
    return {"message": f"'{source}' 삭제 완료 ({deleted}개 청크)"}


@router.get("/status", response_model=StatusResponse)
async def get_status():
    """
    서버 및 인덱싱 현황 조회
    GET /documents/status
    """
    return StatusResponse(
        status="ok",
        total_chunks=vector_store.get_document_count(),
        sources=vector_store.list_sources(),
        model=config.GROQ_MODEL
    )


@router.post("/search", response_model=List[SearchResult])
async def search_documents(request: SearchRequest):
    """
    유사 문서 검색 (디버그/테스트용)
    POST /documents/search

    RAG가 어떤 문서를 찾아오는지 확인할 때 사용
    """
    docs = vector_store.search(request.query, top_k=request.top_k)
    return [SearchResult(**doc) for doc in docs]
