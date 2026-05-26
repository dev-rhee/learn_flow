# ─────────────────────────────────────────────
# Stage 1 — Build
# Gradle 의존성 캐싱을 최대한 활용하기 위해
# 의존성 레이어와 빌드 레이어를 분리한다.
# ─────────────────────────────────────────────
FROM eclipse-temurin:17-jdk-alpine AS builder

WORKDIR /app

# Install Gradle
RUN apk add --no-cache gradle

# 의존성만 먼저 복사 → 소스 변경 시 이 레이어는 캐시 재사용
COPY build.gradle .
COPY settings.gradle* .

RUN gradle dependencies --no-daemon -q || true

# 소스 복사 후 빌드
COPY src src
RUN gradle bootJar --no-daemon -x test

# ─────────────────────────────────────────────
# Stage 2 — Runtime
# JRE만 포함한 경량 이미지 사용
# ─────────────────────────────────────────────
FROM eclipse-temurin:17-jre-alpine AS runtime

WORKDIR /app

# 보안: root 대신 전용 유저로 실행
RUN addgroup -S learnflow && adduser -S learnflow -G learnflow
USER learnflow

COPY --from=builder /app/build/libs/*.jar app.jar

# 타임존 설정
ENV TZ=Asia/Seoul

# 헬스체크
HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=3 \
  CMD wget -qO- http://localhost:8080/actuator/health || exit 1

EXPOSE 8080

ENTRYPOINT ["java", \
  "-XX:+UseContainerSupport", \
  "-XX:MaxRAMPercentage=75.0", \
  "-Djava.security.egd=file:/dev/./urandom", \
  "-jar", "app.jar"]
