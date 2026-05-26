"""
routers/chat_router.py
─────────────────────────────────────────────────────────
역할: 채팅 관련 HTTP 엔드포인트 정의

Spring Boot의 @RestController + @RequestMapping 역할
"""

from fastapi import APIRouter
from fastapi.responses import StreamingResponse
from models.schemas import ChatRequest, ChatResponse
from services.rag_service import rag_service

router = APIRouter(prefix="/chat", tags=["chat"])


@router.post("/stream")
async def stream_chat(request: ChatRequest):
    """
    RAG 기반 스트리밍 채팅 응답
    POST /chat/stream

    Spring Boot의 ChatService가 이 엔드포인트를 호출함
    응답: text/event-stream (SSE 형식)

    SSE 형식:
      data: 안
      data: 녕
      data: 하세요
      data: [DONE]
    """

    def generate():
        # rag_service.stream_answer()에서 텍스트 조각이 yield될 때마다
        # SSE 형식("data: 텍스트\n\n")으로 변환해서 전송
        for chunk in rag_service.stream_answer(
            question=request.question,
            history=[m.dict() for m in request.history]
        ):
            # SSE 형식: "data: " + 내용 + "\n\n"
            yield f"data: {chunk}\n\n"

        # 스트림 종료 신호
        yield "data: [DONE]\n\n"

    return StreamingResponse(
        generate(),
        media_type="text/event-stream",
        headers={
            # 캐싱 방지 (실시간 스트리밍)
            "Cache-Control": "no-cache",
            "X-Accel-Buffering": "no",  # Nginx 버퍼링 비활성화
        }
    )


@router.post("/answer", response_model=ChatResponse)
async def answer_chat(request: ChatRequest):
    """
    스트리밍 없이 전체 응답 반환 (테스트용)
    POST /chat/answer
    """
    result = rag_service.answer(
        question=request.question,
        history=[m.dict() for m in request.history]
    )
    return result
