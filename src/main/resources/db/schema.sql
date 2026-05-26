-- =============================================
-- LearnFlow DDL — Multi-tenant LMS Schema
-- =============================================

-- ── 테넌트 (대학/기관) ──
CREATE TABLE IF NOT EXISTS tenant (
    id          VARCHAR(50)  PRIMARY KEY,
    name        VARCHAR(200) NOT NULL,
    domain      VARCHAR(200) UNIQUE,
    active      BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ── 역할 ──
CREATE TABLE IF NOT EXISTS role (
    id          BIGSERIAL    PRIMARY KEY,
    name        VARCHAR(50)  NOT NULL UNIQUE,
    description VARCHAR(200)
);

-- ── 권한 ──
CREATE TABLE IF NOT EXISTS permission (
    id          BIGSERIAL    PRIMARY KEY,
    name        VARCHAR(100) NOT NULL UNIQUE,
    description VARCHAR(200)
);

-- ── 역할-권한 매핑 ──
CREATE TABLE IF NOT EXISTS role_permission (
    role_id       BIGINT NOT NULL REFERENCES role(id),
    permission_id BIGINT NOT NULL REFERENCES permission(id),
    PRIMARY KEY (role_id, permission_id)
);

-- ── 사용자 ──
CREATE TABLE IF NOT EXISTS users (
    id          BIGSERIAL    PRIMARY KEY,
    tenant_id   VARCHAR(50)  NOT NULL REFERENCES tenant(id),
    email       VARCHAR(200) NOT NULL,
    password    VARCHAR(255) NOT NULL,
    name        VARCHAR(100) NOT NULL,
    role_id     BIGINT       NOT NULL REFERENCES role(id),
    active      BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (tenant_id, email)
);

-- ── 강좌 ──
CREATE TABLE IF NOT EXISTS course (
    id           BIGSERIAL    PRIMARY KEY,
    tenant_id    VARCHAR(50)  NOT NULL REFERENCES tenant(id),
    title        VARCHAR(300) NOT NULL,
    description  TEXT,
    instructor_id BIGINT      NOT NULL REFERENCES users(id),
    status       VARCHAR(20)  NOT NULL DEFAULT 'DRAFT', -- DRAFT | PUBLISHED | CLOSED
    max_students INT,
    completion_rate_required NUMERIC(5,2) NOT NULL DEFAULT 80.00,
    created_at   TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ── 수강 신청 ──
CREATE TABLE IF NOT EXISTS enrollment (
    id          BIGSERIAL   PRIMARY KEY,
    tenant_id   VARCHAR(50) NOT NULL REFERENCES tenant(id),
    course_id   BIGINT      NOT NULL REFERENCES course(id),
    user_id     BIGINT      NOT NULL REFERENCES users(id),
    status      VARCHAR(20) NOT NULL DEFAULT 'ACTIVE', -- ACTIVE | COMPLETED | CANCELLED
    enrolled_at TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP,
    UNIQUE (tenant_id, course_id, user_id)
);

-- ── 강의(챕터) ──
CREATE TABLE IF NOT EXISTS lesson (
    id          BIGSERIAL    PRIMARY KEY,
    tenant_id   VARCHAR(50)  NOT NULL REFERENCES tenant(id),
    course_id   BIGINT       NOT NULL REFERENCES course(id),
    title       VARCHAR(300) NOT NULL,
    sort_order  INT          NOT NULL DEFAULT 0,
    duration_sec INT         NOT NULL DEFAULT 0,
    video_url   VARCHAR(500)
);

-- ── 수강 진도 ──
CREATE TABLE IF NOT EXISTS progress (
    id              BIGSERIAL   PRIMARY KEY,
    tenant_id       VARCHAR(50) NOT NULL REFERENCES tenant(id),
    enrollment_id   BIGINT      NOT NULL REFERENCES enrollment(id),
    lesson_id       BIGINT      NOT NULL REFERENCES lesson(id),
    watched_sec     INT         NOT NULL DEFAULT 0,
    completed       BOOLEAN     NOT NULL DEFAULT FALSE,
    last_watched_at TIMESTAMP,
    UNIQUE (tenant_id, enrollment_id, lesson_id)
);

-- ── 집계 요약 테이블 (배치 사전 집계) ──
CREATE TABLE IF NOT EXISTS progress_summary (
    id              BIGSERIAL   PRIMARY KEY,
    tenant_id       VARCHAR(50) NOT NULL REFERENCES tenant(id),
    enrollment_id   BIGINT      NOT NULL REFERENCES enrollment(id),
    total_lessons   INT         NOT NULL DEFAULT 0,
    completed_lessons INT       NOT NULL DEFAULT 0,
    completion_rate NUMERIC(5,2) NOT NULL DEFAULT 0.00,
    last_updated_at TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (tenant_id, enrollment_id)
);

-- ── 인덱스 ──
CREATE INDEX IF NOT EXISTS idx_users_tenant         ON users(tenant_id);
CREATE INDEX IF NOT EXISTS idx_course_tenant        ON course(tenant_id);
CREATE INDEX IF NOT EXISTS idx_enrollment_tenant    ON enrollment(tenant_id);
CREATE INDEX IF NOT EXISTS idx_enrollment_user      ON enrollment(tenant_id, user_id);
CREATE INDEX IF NOT EXISTS idx_progress_tenant      ON progress(tenant_id);
CREATE INDEX IF NOT EXISTS idx_progress_enrollment  ON progress(tenant_id, enrollment_id);
CREATE INDEX IF NOT EXISTS idx_summary_tenant       ON progress_summary(tenant_id);
