"""
services/rag_service.py
─────────────────────────────────────────────────────────
역할: RAG의 핵심 로직

RAG 전체 흐름:
  1. 사용자 질문 수신
  2. 질문을 벡터로 변환 → Chroma에서 유사 문서 검색
  3. 검색된 문서 + 질문 + 대화 히스토리 → 프롬프트 조립
  4. 조립된 프롬프트 → Groq LLM에 전달
  5. LLM 응답을 스트리밍으로 반환

일반 챗봇과의 차이:
  일반: 질문 → LLM → 답변 (LLM이 아는 것만 답변)
  RAG:  질문 → [내 문서 검색] → 문서+질문 → LLM → 답변 (내 문서 기반 답변)
"""

from groq import Groq
from typing import List, Dict, Any, Generator
from config import config
from services.vector_store_service import vector_store


class RagService:

    def __init__(self):
        # Groq 클라이언트 초기화
        self.groq = Groq(api_key=config.GROQ_API_KEY)

    # ─────────────────────────────────────────────
    # 메인: RAG 스트리밍 응답
    # ─────────────────────────────────────────────

    def stream_answer(
        self,
        question: str,
        history: List[Dict[str, str]] = None
    ) -> Generator[str, None, None]:
        """
        질문에 대한 RAG 기반 스트리밍 답변 생성

        Args:
            question: 사용자 질문
            history:  이전 대화 히스토리 [{"role": "user", "content": "..."}, ...]

        Yields:
            텍스트 조각 (스트리밍)
        """
        # 1단계: 관련 문서 검색
        relevant_docs = vector_store.search(question, top_k=config.TOP_K)

        # 2단계: 프롬프트 조립
        messages = self._build_messages(question, history or [], relevant_docs)

        # 3단계: Groq API 스트리밍 호출
        yield from self._stream_groq(messages)

    def answer(
        self,
        question: str,
        history: List[Dict[str, str]] = None
    ) -> Dict[str, Any]:
        """
        스트리밍 없이 전체 답변 반환 (테스트용)
        """
        relevant_docs = vector_store.search(question, top_k=config.TOP_K)
        messages = self._build_messages(question, history or [], relevant_docs)

        response = self.groq.chat.completions.create(
            model=config.GROQ_MODEL,
            messages=messages,
            max_tokens=2048,
            temperature=0.3
        )

        return {
            "answer": response.choices[0].message.content,
            "sources": [
                {"source": d["source"], "score": d["score"], "page": d["page"]}
                for d in relevant_docs
            ]
        }

    # ─────────────────────────────────────────────
    # 프롬프트 조립
    # ─────────────────────────────────────────────

    def _build_messages(
        self,
        question: str,
        history: List[Dict],
        docs: List[Dict]
    ) -> List[Dict[str, str]]:
        """
        LLM에 보낼 메시지 배열 조립

        최종 구조:
          [
            {"role": "system", "content": "시스템 프롬프트 + 참고 문서"},
            {"role": "user",   "content": "이전 질문1"},
            {"role": "assistant", "content": "이전 답변1"},
            ...
            {"role": "user",   "content": "현재 질문"}
          ]
        """
        messages = []

        # ── 시스템 메시지 (문서 컨텍스트 포함) ──────────
        if docs:
            # 검색된 문서들을 시스템 프롬프트에 삽입
            context_parts = []
            for i, doc in enumerate(docs, start=1):
                context_parts.append(
                    f"[문서 {i}] 출처: {doc['source']} (유사도: {doc['score']})\n"
                    f"{doc['text']}"
                )
            context = "\n\n".join(context_parts)

            system_content = f"""{config.SYSTEM_PROMPT}

[참고 문서]
{context}
"""
        else:
            # 관련 문서가 없을 때
            system_content = (
                config.SYSTEM_PROMPT
                + "\n\n[참고 문서]\n인덱싱된 문서가 없습니다. "
                  "먼저 문서를 업로드해주세요."
            )

        messages.append({"role": "system", "content": system_content})

        # ── 이전 대화 히스토리 (멀티턴) ─────────────────
        # 최근 10개만 유지 (너무 많으면 토큰 초과)
        recent_history = history[-10:] if len(history) > 10 else history
        for msg in recent_history:
            messages.append({
                "role": msg["role"],
                "content": msg["content"]
            })

        # ── 현재 질문 ────────────────────────────────────
        messages.append({"role": "user", "content": question})

        return messages

    # ─────────────────────────────────────────────
    # Groq 스트리밍 호출
    # ─────────────────────────────────────────────

    def _stream_groq(self, messages: List[Dict]) -> Generator[str, None, None]:
        """
        Groq API에 스트리밍 요청 후 텍스트 조각을 yield

        stream=True 설정 시 Groq는 SSE 형식으로 응답:
          data: {"choices": [{"delta": {"content": "안"}}]}
          data: {"choices": [{"delta": {"content": "녕"}}]}
          ...
          data: [DONE]
        """
        stream = self.groq.chat.completions.create(
            model=config.GROQ_MODEL,
            messages=messages,
            max_tokens=2048,
            temperature=0.3,   # RAG는 낮게 설정 (문서 기반 정확한 답변)
            stream=True
        )

        for chunk in stream:
            # 각 청크에서 텍스트 조각 추출
            content = chunk.choices[0].delta.content
            if content:
                yield content


# 싱글턴 인스턴스
rag_service = RagService()
