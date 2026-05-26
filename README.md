# LearnFlow — 멀티 테넌트 LMS 백엔드

> **포트폴리오 핵심 주제**: 멀티 테넌트 데이터 격리 + Spring Security RBAC 권한 체계

---

## 기술 스택

| 영역 | 기술 |
|---|---|
| Language | Java 17 |
| Framework | Spring Boot 3.2, Spring Security 6 |
| Persistence | MyBatis 3, PostgreSQL |
| Auth | JWT (jjwt 0.12) |
| Build | Gradle |

---

## 핵심 구현 포인트

### 1. 멀티 테넌트 데이터 격리 — `TenantInterceptor`

```
요청 → JwtAuthenticationFilter
         └─ TenantContext.setTenantId("univ_a")  // ① JWT 파싱 시 저장
              └─ MyBatis Executor.query()
                   └─ TenantInterceptor 가로채기  // ② SQL 실행 전 인터셉트
                        └─ WHERE tenant_id = 'univ_a' 자동 주입  // ③ 격리 보장
```

- `MyBatis Interceptor`가 모든 SELECT 실행 전 `tenant_id` 조건을 자동 주입
- 개발자가 쿼리에 조건을 빠뜨려도 크로스 테넌트 접근이 구조적으로 불가능
- 요청 종료 시 `TenantContext.clear()`로 ThreadLocal 누수 방지

### 2. Spring Security RBAC 권한 체계

```
Role (역할)      Permission (개별 권한)
─────────────    ─────────────────────
ROLE_ADMIN    →  course:read, course:write, course:delete, user:write, ...
ROLE_INSTRUCTOR→  course:read, course:write, enrollment:read, ...
ROLE_STUDENT  →  course:read, enrollment:read, enrollment:write, progress:write
```

- `role_permission` 매핑 테이블로 DB에서 권한 관리
- Spring Security `hasAuthority()`로 URL 단위 선언적 제어
- `@PreAuthorize`로 서비스 메서드 단위 2차 권한 검증
- 새 권한 추가 시 코드 변경 없이 DB 매핑만 추가

### 3. 배치 집계로 응답 성능 확보

```
매일 새벽 2시: rebuildSummaryAll()     → progress_summary 전체 재집계
매 1시간:      upsertSummaryAfter()   → 최근 1시간 변경분 증분 갱신

관리자 조회 → progress_summary 단순 SELECT → 0.3초 이하 응답
```

---

## 프로젝트 구조

```
src/main/java/com/learnflow/
├── LearnFlowApplication.java
├── config/
│   └── SecurityConfig.java          # Spring Security 6 설정
├── domain/
│   ├── course/                      # 강좌 도메인
│   ├── enrollment/                  # 수강 신청 도메인
│   ├── progress/                    # 진도·수료 도메인 + 배치
│   └── user/                        # 사용자·인증 도메인
└── global/
    ├── interceptor/
    │   ├── TenantContext.java        # ThreadLocal 테넌트 홀더
    │   └── TenantInterceptor.java   # ★ 핵심: MyBatis 자동 격리
    ├── security/
    │   ├── JwtProvider.java
    │   ├── JwtAuthenticationFilter.java
    │   ├── UserPrincipal.java
    │   ├── Permission.java           # 권한 상수
    │   └── LearnFlowUserDetailsService.java
    ├── exception/
    └── response/
```

---

## 실행 방법

### 1. PostgreSQL 준비

```sql
CREATE DATABASE learnflow;
CREATE USER learnflow WITH PASSWORD 'learnflow';
GRANT ALL PRIVILEGES ON DATABASE learnflow TO learnflow;
```

### 2. 실행

```bash
./gradlew bootRun
```

스키마와 초기 데이터는 자동으로 적용됩니다.

---

## API 명세

### 인증

```http
POST /api/auth/login
{
  "email":    "admin@hanbit.ac.kr",
  "password": "test1234",
  "tenantId": "univ_a"
}
```

### 강좌

```http
GET    /api/courses          # 강좌 목록 (tenant 자동 필터)
GET    /api/courses/{id}     # 강좌 상세
POST   /api/courses          # 강좌 등록 (INSTRUCTOR, ADMIN)
PUT    /api/courses/{id}     # 강좌 수정 (INSTRUCTOR, ADMIN)
DELETE /api/courses/{id}     # 강좌 삭제 (ADMIN)
```

### 수강

```http
GET  /api/enrollments/my             # 내 수강 목록
POST /api/enrollments/{courseId}     # 수강 신청
```

### 진도

```http
POST /api/progress                   # 진도 저장
GET  /api/progress/{enrollmentId}    # 진도 조회
GET  /api/reports/courses/{courseId}/progress  # 강좌 전체 진도 (배치 집계)
```

---

## 테스트 계정

| 역할 | 이메일 | 비밀번호 | 테넌트 |
|---|---|---|---|
| 관리자 | admin@hanbit.ac.kr | test1234 | univ_a |
| 교수 | prof.kim@hanbit.ac.kr | test1234 | univ_a |
| 학생 | student1@hanbit.ac.kr | test1234 | univ_a |
| 관리자 | admin@mirae.ac.kr | test1234 | univ_b |
