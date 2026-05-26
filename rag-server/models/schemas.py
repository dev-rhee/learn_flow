"""
models/schemas.py
─────────────────────────────────────────────────────────
역할: API 요청/응답 데이터 구조 정의

Spring Boot의 DTO(Data Transfer Object)와 동일한 역할
Pydantic을 사용하면 타입 검증 + 자동 직렬화/역직렬화
"""

from pydantic import BaseModel, Field
from typing import List, Optional, Any, Dict


# ─────────────────────────────────────────────
# 공통
# ─────────────────────────────────────────────

class MessageDto(BaseModel):
    """대화 메시지 단위 (멀티턴용)"""
    role: str        # "user" | "assistant"
    content: str


# ─────────────────────────────────────────────
# 채팅 API
# ─────────────────────────────────────────────

class ChatRequest(BaseModel):
    """Spring Boot → Python RAG 서버로 오는 채팅 요청"""
    question: str = Field(..., min_length=1, description="사용자 질문")
    history: List[MessageDto] = Field(
        default=[],
        description="이전 대화 히스토리 (멀티턴)"
    )


class SourceInfo(BaseModel):
    """참고 문서 출처 정보"""
    source: str      # 파일명 또는 DB 테이블명
    score: float     # 유사도 (0~1)
    page: int = 0    # PDF 페이지 번호


class ChatResponse(BaseModel):
    """스트리밍 없이 전체 응답 반환 시 (테스트용)"""
    answer: str
    sources: List[SourceInfo]


# ─────────────────────────────────────────────
# 문서 관리 API
# ─────────────────────────────────────────────

class DbIndexRequest(BaseModel):
    """DB 테이블 인덱싱 요청"""
    table_name: str = Field(..., description="인덱싱할 테이블명")
    text_columns: List[str] = Field(..., description="텍스트로 저장할 컬럼들")
    id_column: str = Field(default="id", description="PK 컬럼명")


class IndexResponse(BaseModel):
    """인덱싱 결과 응답"""
    message: str
    chunks: int       # 저장된 청크 수
    source: str       # 인덱싱된 소스 이름


# ─────────────────────────────────────────────
# 상태 조회 API
# ─────────────────────────────────────────────

class StatusResponse(BaseModel):
    """서버 및 DB 상태"""
    status: str = "ok"
    total_chunks: int       # 전체 저장된 청크 수
    sources: List[str]      # 인덱싱된 소스 목록
    model: str              # 사용 중인 LLM 모델


class SearchRequest(BaseModel):
    """유사 문서 검색 요청 (디버그용)"""
    query: str
    top_k: int = 5


class SearchResult(BaseModel):
    """검색 결과"""
    text: str
    source: str
    score: float
    page: int = 0
