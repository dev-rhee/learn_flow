"""
main.py
─────────────────────────────────────────────────────────
역할: FastAPI 앱 생성 및 설정

Spring Boot의 ChatbotApplication.java + WebMvcConfig 역할
"""

import os
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from routers import chat_router, document_router

# FastAPI 앱 생성
app = FastAPI(
    title="RAG 챗봇 엔진",
    description="PDF, DB 데이터 기반 RAG 챗봇 API",
    version="1.0.0",
    # /docs 에서 Swagger UI로 API 테스트 가능
)

# ── CORS 설정 ─────────────────────────────────
# Spring Boot(8080)에서 Python(8001)으로 요청할 때 필요
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:8080",   # Spring Boot 개발 서버
        "http://localhost:3000",   # 프론트엔드 개발 서버
    ],
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── 라우터 등록 ────────────────────────────────
app.include_router(chat_router.router)
app.include_router(document_router.router)


@app.get("/health")
async def health_check():
    """헬스 체크 (Spring Boot에서 Python 서버 상태 확인용)"""
    return {"status": "ok", "service": "RAG Engine"}


# ── 서버 실행 ──────────────────────────────────
if __name__ == "__main__":
    import uvicorn
    port = int(os.getenv("PORT", "8001"))
    print(f"RAG 서버 시작: http://localhost:{port}")
    print(f"API 문서: http://localhost:{port}/docs")
    uvicorn.run("main:app", host="0.0.0.0", port=port, reload=True)
