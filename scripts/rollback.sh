#!/bin/bash
# =====================================================
# 롤백 스크립트
# 사용: bash scripts/rollback.sh [IMAGE_TAG]
# 예시: bash scripts/rollback.sh abc1234
# 태그 생략 시 latest-1 (직전 이미지)로 롤백
# =====================================================
set -e

DOCKERHUB_USERNAME="${DOCKERHUB_USERNAME:-your-username}"
IMAGE_BASE="$DOCKERHUB_USERNAME/learnflow"
ROLLBACK_TAG="${1:-}"
APP_DIR=~/learnflow

echo "================================================"
echo "  LearnFlow 롤백"
echo "================================================"

cd $APP_DIR

if [ -z "$ROLLBACK_TAG" ]; then
  echo "⚠️  태그 미지정 — 현재 컨테이너의 직전 이미지로 롤백 시도"

  # 현재 실행 중인 이미지 확인
  CURRENT=$(docker inspect learnflow-app --format='{{.Config.Image}}' 2>/dev/null || echo "none")
  echo "현재 이미지: $CURRENT"

  # Docker Hub에서 이전 태그 목록 확인 안내
  echo ""
  echo "사용 가능한 이미지 태그 확인:"
  echo "  docker images $IMAGE_BASE"
  echo ""
  echo "롤백할 태그를 지정해주세요:"
  echo "  bash scripts/rollback.sh [SHA_TAG]"
  exit 1
fi

ROLLBACK_IMAGE="$IMAGE_BASE:$ROLLBACK_TAG"
echo "롤백 대상: $ROLLBACK_IMAGE"

# 이미지 Pull
echo ""
echo "[1/3] 롤백 이미지 Pull..."
docker pull $ROLLBACK_IMAGE

# .env의 DOCKER_IMAGE 교체
echo ""
echo "[2/3] 이미지 태그 전환..."
sed -i "s|DOCKER_IMAGE=.*|DOCKER_IMAGE=$ROLLBACK_IMAGE|" .env
export DOCKER_IMAGE=$ROLLBACK_IMAGE
source .env

# 재시작
echo ""
echo "[3/3] 컨테이너 재시작..."
docker-compose up -d --no-deps app

# 헬스체크
echo ""
echo "헬스체크 대기 중..."
for i in $(seq 1 12); do
  if curl -sf http://localhost:8080/actuator/health > /dev/null; then
    echo "✅ 롤백 완료: $ROLLBACK_IMAGE"
    exit 0
  fi
  echo "대기 중... ($i/12)"
  sleep 5
done

echo "❌ 롤백 후 헬스체크 실패. 로그 확인:"
echo "  docker logs learnflow-app --tail=50"
exit 1
