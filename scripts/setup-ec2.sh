#!/bin/bash
# =====================================================
# EC2 최초 세팅 스크립트 (Ubuntu 22.04 기준)
# 로컬에서 실행: bash scripts/setup-ec2.sh
# EC2에서 직접 실행: bash <(curl -s [이 파일 raw URL])
# =====================================================
set -e

echo "================================================"
echo "  LearnFlow EC2 초기 세팅"
echo "================================================"

# ── 1. 패키지 업데이트 ──────────────────────────────
echo ""
echo "[1/6] 패키지 업데이트..."
sudo apt-get update -y
sudo apt-get upgrade -y

# ── 2. Docker 설치 ──────────────────────────────────
echo ""
echo "[2/6] Docker 설치..."
if ! command -v docker &> /dev/null; then
  curl -fsSL https://get.docker.com | sudo sh
  sudo usermod -aG docker $USER
  sudo systemctl enable docker
  sudo systemctl start docker
  echo "✅ Docker 설치 완료: $(docker --version)"
else
  echo "✅ Docker 이미 설치됨: $(docker --version)"
fi

# ── 3. Docker Compose v2 설치 ───────────────────────
echo ""
echo "[3/6] Docker Compose 설치..."
if ! docker compose version &> /dev/null; then
  COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest \
    | grep '"tag_name"' | cut -d'"' -f4)
  sudo curl -L \
    "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" \
    -o /usr/local/bin/docker-compose
  sudo chmod +x /usr/local/bin/docker-compose
  echo "✅ Docker Compose 설치 완료: $(docker-compose --version)"
else
  echo "✅ Docker Compose 이미 설치됨"
fi

# ── 4. 방화벽 설정 ──────────────────────────────────
echo ""
echo "[4/6] 방화벽 설정..."
sudo ufw allow 22    # SSH
sudo ufw allow 80    # HTTP
sudo ufw allow 443   # HTTPS
sudo ufw --force enable
echo "✅ UFW 방화벽 활성화 (22, 80, 443 허용)"

# ── 5. 앱 디렉토리 구성 ─────────────────────────────
echo ""
echo "[5/6] 앱 디렉토리 구성..."
APP_DIR=~/learnflow
mkdir -p $APP_DIR/docker/ssl
mkdir -p $APP_DIR/logs

# .env 파일 템플릿 생성 (실제 값은 직접 수정)
if [ ! -f "$APP_DIR/.env" ]; then
cat > $APP_DIR/.env << 'EOF'
# ⚠️  이 파일의 값을 실제 값으로 교체하세요
DOCKER_IMAGE=your-dockerhub-username/learnflow:latest
DB_PASSWORD=your-strong-password-here
JWT_SECRET=your-jwt-secret-at-least-32-chars
SPRING_PROFILES_ACTIVE=prod
EOF
  echo "✅ .env 템플릿 생성: $APP_DIR/.env (값 교체 필요)"
else
  echo "✅ .env 이미 존재함"
fi

# docker-compose 파일 다운로드 (GitHub에서)
# 실제 사용 시 아래 URL을 본인 레포지토리 raw URL로 변경
cat > $APP_DIR/docker-compose.yml << 'COMPOSE'
version: '3.9'
services:
  postgres:
    image: postgres:16-alpine
    container_name: learnflow-db
    restart: unless-stopped
    environment:
      POSTGRES_DB: learnflow
      POSTGRES_USER: learnflow
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - learnflow-net
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U learnflow"]
      interval: 10s
      timeout: 5s
      retries: 5

  app:
    image: ${DOCKER_IMAGE}
    container_name: learnflow-app
    restart: unless-stopped
    depends_on:
      postgres:
        condition: service_healthy
    environment:
      SPRING_DATASOURCE_URL: jdbc:postgresql://postgres:5432/learnflow
      SPRING_DATASOURCE_USERNAME: learnflow
      SPRING_DATASOURCE_PASSWORD: ${DB_PASSWORD}
      JWT_SECRET: ${JWT_SECRET}
      SPRING_PROFILES_ACTIVE: ${SPRING_PROFILES_ACTIVE:-prod}
    ports:
      - "8080:8080"
    networks:
      - learnflow-net
    logging:
      driver: json-file
      options:
        max-size: "10m"
        max-file: "5"

  nginx:
    image: nginx:1.25-alpine
    container_name: learnflow-nginx
    restart: unless-stopped
    depends_on:
      - app
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./docker/nginx.conf:/etc/nginx/nginx.conf:ro
      - ./docker/ssl:/etc/nginx/ssl:ro
    networks:
      - learnflow-net

volumes:
  postgres_data:

networks:
  learnflow-net:
    driver: bridge
COMPOSE

# ── 6. 로그 로테이션 설정 ───────────────────────────
echo ""
echo "[6/6] 로그 로테이션 설정..."
sudo tee /etc/logrotate.d/learnflow > /dev/null << 'EOF'
/home/ubuntu/learnflow/logs/*.log {
    daily
    rotate 14
    compress
    missingok
    notifempty
}
EOF

echo ""
echo "================================================"
echo "  ✅ EC2 초기 세팅 완료!"
echo "================================================"
echo ""
echo "다음 단계:"
echo "  1. $APP_DIR/.env 파일의 값을 실제 값으로 교체"
echo "  2. SSL 인증서를 $APP_DIR/docker/ssl/ 에 배치"
echo "  3. docker/nginx.conf 를 서버에 복사"
echo "  4. GitHub Secrets 설정 후 Actions 실행"
echo ""
echo "  ⚠️  'docker' 그룹 적용을 위해 재로그인이 필요합니다:"
echo "     exit 후 다시 SSH 접속"
