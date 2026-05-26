"""
services/embedding_service.py
─────────────────────────────────────────────────────────
역할: 텍스트를 벡터(숫자 배열)로 변환하는 서비스

RAG의 핵심 원리:
  "고양이가 밥을 먹는다" → [0.12, -0.34, 0.87, ...]  (384차원 숫자 배열)
  "강아지가 사료를 먹었다" → [0.11, -0.31, 0.85, ...]  (비슷한 의미 → 비슷한 숫자)

  사용자 질문도 벡터로 변환 후, 저장된 문서 벡터들과 거리를 계산해서
  가장 가까운(의미가 비슷한) 문서를 찾아옴
"""

from config import config
from typing import List


class EmbeddingService:

    def __init__(self):
        self._model = None  # 지연 로딩 (처음 사용할 때 로드)

    def _get_model(self):
        """
        임베딩 모델 로드 (처음 호출 시 한 번만 로드)

        로컬 모델 사용 시: sentence-transformers 라이브러리 필요
          pip install sentence-transformers
        """
        if self._model is None:
            if config.EMBEDDING_TYPE == "local":
                # ── 로컬 무료 모델 ────────────────────────────
                # paraphrase-multilingual: 한국어 포함 50개 언어 지원
                # 처음 실행 시 ~90MB 다운로드 후 로컬 캐시
                from sentence_transformers import SentenceTransformer
                print("임베딩 모델 로딩 중... (최초 1회만)")
                self._model = SentenceTransformer(
                    "paraphrase-multilingual-MiniLM-L12-v2"
                )
                print("임베딩 모델 로딩 완료")
            else:
                # ── OpenAI 임베딩 (유료) ───────────────────────
                from openai import OpenAI
                self._model = OpenAI()

        return self._model

    def embed_texts(self, texts: List[str]) -> List[List[float]]:
        """
        텍스트 리스트를 벡터 리스트로 변환

        Args:
            texts: ["문서1 내용", "문서2 내용", ...]

        Returns:
            [[0.12, -0.34, ...], [0.55, 0.22, ...], ...]
        """
        model = self._get_model()

        if config.EMBEDDING_TYPE == "local":
            # sentence-transformers: encode() 메서드 사용
            embeddings = model.encode(texts, show_progress_bar=False)
            return embeddings.tolist()  # numpy array → Python list
        else:
            # OpenAI: API 호출
            response = model.embeddings.create(
                model="text-embedding-3-small",
                input=texts
            )
            return [item.embedding for item in response.data]

    def embed_query(self, text: str) -> List[float]:
        """
        단일 쿼리 텍스트를 벡터로 변환 (검색 시 사용)

        Args:
            text: "고양이에 대해 알려줘"

        Returns:
            [0.12, -0.34, 0.87, ...]
        """
        return self.embed_texts([text])[0]


# 싱글턴 인스턴스
embedding_service = EmbeddingService()
