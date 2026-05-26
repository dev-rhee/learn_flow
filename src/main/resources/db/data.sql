-- =============================================
-- LearnFlow 초기 데이터 (idempotent)
-- =============================================

-- ── 테넌트 ──
INSERT INTO tenant (id, name, domain) VALUES
    ('univ_a', '한빛대학교', 'hanbit.ac.kr'),
    ('univ_b', '미래대학교',  'mirae.ac.kr')
ON CONFLICT DO NOTHING;

-- ── 역할 ──
INSERT INTO role (name, description) VALUES
    ('ROLE_SUPER_ADMIN', '슈퍼 관리자'),
    ('ROLE_ADMIN',       '기관 관리자'),
    ('ROLE_INSTRUCTOR',  '교수'),
    ('ROLE_STUDENT',     '학생')
ON CONFLICT DO NOTHING;

-- ── 권한 ──
INSERT INTO permission (name, description) VALUES
    ('course:read',      '강좌 조회'),
    ('course:write',     '강좌 등록/수정'),
    ('course:delete',    '강좌 삭제'),
    ('enrollment:read',  '수강 신청 조회'),
    ('enrollment:write', '수강 신청/취소'),
    ('progress:read',    '진도 조회'),
    ('progress:write',   '진도 저장'),
    ('user:read',        '사용자 조회'),
    ('user:write',       '사용자 관리'),
    ('report:read',      '통계/보고서 조회')
ON CONFLICT DO NOTHING;

-- ── 역할-권한 매핑 ──
-- ADMIN: 전체 권한
INSERT INTO role_permission (role_id, permission_id)
SELECT r.id, p.id FROM role r, permission p
WHERE r.name = 'ROLE_ADMIN'
ON CONFLICT DO NOTHING;

-- INSTRUCTOR: 강좌 읽기/쓰기, 수강 조회, 진도 조회, 보고서 조회
INSERT INTO role_permission (role_id, permission_id)
SELECT r.id, p.id FROM role r, permission p
WHERE r.name = 'ROLE_INSTRUCTOR'
  AND p.name IN ('course:read','course:write','enrollment:read','progress:read','report:read')
ON CONFLICT DO NOTHING;

-- STUDENT: 강좌 조회, 수강 조회/신청, 진도 조회/저장
INSERT INTO role_permission (role_id, permission_id)
SELECT r.id, p.id FROM role r, permission p
WHERE r.name = 'ROLE_STUDENT'
  AND p.name IN ('course:read','enrollment:read','enrollment:write','progress:read','progress:write')
ON CONFLICT DO NOTHING;

-- ── 사용자 (password: test1234 → BCrypt) ──
-- univ_a 사용자
INSERT INTO users (tenant_id, email, password, name, role_id)
SELECT 'univ_a', 'admin@hanbit.ac.kr',
       '$2b$10$rvvDRJzwEEbpZBp6BsMZ3.3ytGRRJX8J75KwbfqsO40doxmAItvx.',
       '한빛 관리자', r.id FROM role r WHERE r.name = 'ROLE_ADMIN'
ON CONFLICT DO NOTHING;

INSERT INTO users (tenant_id, email, password, name, role_id)
SELECT 'univ_a', 'prof.kim@hanbit.ac.kr',
       '$2b$10$rvvDRJzwEEbpZBp6BsMZ3.3ytGRRJX8J75KwbfqsO40doxmAItvx.',
       '김교수', r.id FROM role r WHERE r.name = 'ROLE_INSTRUCTOR'
ON CONFLICT DO NOTHING;

INSERT INTO users (tenant_id, email, password, name, role_id)
SELECT 'univ_a', 'prof.lee@hanbit.ac.kr',
       '$2b$10$rvvDRJzwEEbpZBp6BsMZ3.3ytGRRJX8J75KwbfqsO40doxmAItvx.',
       '이교수', r.id FROM role r WHERE r.name = 'ROLE_INSTRUCTOR'
ON CONFLICT DO NOTHING;

INSERT INTO users (tenant_id, email, password, name, role_id)
SELECT 'univ_a', 'student1@hanbit.ac.kr',
       '$2b$10$rvvDRJzwEEbpZBp6BsMZ3.3ytGRRJX8J75KwbfqsO40doxmAItvx.',
       '이수강', r.id FROM role r WHERE r.name = 'ROLE_STUDENT'
ON CONFLICT DO NOTHING;

INSERT INTO users (tenant_id, email, password, name, role_id)
SELECT 'univ_a', 'student2@hanbit.ac.kr',
       '$2b$10$rvvDRJzwEEbpZBp6BsMZ3.3ytGRRJX8J75KwbfqsO40doxmAItvx.',
       '박수강', r.id FROM role r WHERE r.name = 'ROLE_STUDENT'
ON CONFLICT DO NOTHING;

INSERT INTO users (tenant_id, email, password, name, role_id)
SELECT 'univ_a', 'student3@hanbit.ac.kr',
       '$2b$10$rvvDRJzwEEbpZBp6BsMZ3.3ytGRRJX8J75KwbfqsO40doxmAItvx.',
       '최학생', r.id FROM role r WHERE r.name = 'ROLE_STUDENT'
ON CONFLICT DO NOTHING;

INSERT INTO users (tenant_id, email, password, name, role_id)
SELECT 'univ_a', 'student4@hanbit.ac.kr',
       '$2b$10$rvvDRJzwEEbpZBp6BsMZ3.3ytGRRJX8J75KwbfqsO40doxmAItvx.',
       '정공부', r.id FROM role r WHERE r.name = 'ROLE_STUDENT'
ON CONFLICT DO NOTHING;

INSERT INTO users (tenant_id, email, password, name, role_id)
SELECT 'univ_a', 'student5@hanbit.ac.kr',
       '$2b$10$rvvDRJzwEEbpZBp6BsMZ3.3ytGRRJX8J75KwbfqsO40doxmAItvx.',
       '윤배움', r.id FROM role r WHERE r.name = 'ROLE_STUDENT'
ON CONFLICT DO NOTHING;

-- univ_b 사용자
INSERT INTO users (tenant_id, email, password, name, role_id)
SELECT 'univ_b', 'admin@mirae.ac.kr',
       '$2b$10$rvvDRJzwEEbpZBp6BsMZ3.3ytGRRJX8J75KwbfqsO40doxmAItvx.',
       '미래 관리자', r.id FROM role r WHERE r.name = 'ROLE_ADMIN'
ON CONFLICT DO NOTHING;

INSERT INTO users (tenant_id, email, password, name, role_id)
SELECT 'univ_b', 'prof.park@mirae.ac.kr',
       '$2b$10$rvvDRJzwEEbpZBp6BsMZ3.3ytGRRJX8J75KwbfqsO40doxmAItvx.',
       '박교수', r.id FROM role r WHERE r.name = 'ROLE_INSTRUCTOR'
ON CONFLICT DO NOTHING;

INSERT INTO users (tenant_id, email, password, name, role_id)
SELECT 'univ_b', 'student1@mirae.ac.kr',
       '$2b$10$rvvDRJzwEEbpZBp6BsMZ3.3ytGRRJX8J75KwbfqsO40doxmAItvx.',
       '김미래', r.id FROM role r WHERE r.name = 'ROLE_STUDENT'
ON CONFLICT DO NOTHING;

INSERT INTO users (tenant_id, email, password, name, role_id)
SELECT 'univ_b', 'student2@mirae.ac.kr',
       '$2b$10$rvvDRJzwEEbpZBp6BsMZ3.3ytGRRJX8J75KwbfqsO40doxmAItvx.',
       '이미래', r.id FROM role r WHERE r.name = 'ROLE_STUDENT'
ON CONFLICT DO NOTHING;

-- ── 강좌 (course) ──
-- univ_a 강좌 5개
INSERT INTO course (tenant_id, title, description, instructor_id, status, max_students, completion_rate_required)
SELECT 'univ_a', 'Java 기초 프로그래밍',
       'Java 언어의 기초부터 객체지향 프로그래밍까지 단계별로 학습합니다.',
       u.id, 'PUBLISHED', 40, 80.00
FROM users u WHERE u.email = 'prof.kim@hanbit.ac.kr' AND u.tenant_id = 'univ_a'
  AND NOT EXISTS (SELECT 1 FROM course WHERE title = 'Java 기초 프로그래밍' AND tenant_id = 'univ_a');

INSERT INTO course (tenant_id, title, description, instructor_id, status, max_students, completion_rate_required)
SELECT 'univ_a', '데이터베이스 설계와 SQL',
       '관계형 데이터베이스 이론과 SQL 실무 쿼리 작성을 다룹니다.',
       u.id, 'PUBLISHED', 35, 75.00
FROM users u WHERE u.email = 'prof.kim@hanbit.ac.kr' AND u.tenant_id = 'univ_a'
  AND NOT EXISTS (SELECT 1 FROM course WHERE title = '데이터베이스 설계와 SQL' AND tenant_id = 'univ_a');

INSERT INTO course (tenant_id, title, description, instructor_id, status, max_students, completion_rate_required)
SELECT 'univ_a', '웹 프론트엔드 입문',
       'HTML, CSS, JavaScript를 이용한 웹 페이지 제작의 기초를 배웁니다.',
       u.id, 'PUBLISHED', 50, 70.00
FROM users u WHERE u.email = 'prof.lee@hanbit.ac.kr' AND u.tenant_id = 'univ_a'
  AND NOT EXISTS (SELECT 1 FROM course WHERE title = '웹 프론트엔드 입문' AND tenant_id = 'univ_a');

INSERT INTO course (tenant_id, title, description, instructor_id, status, max_students, completion_rate_required)
SELECT 'univ_a', 'Spring Boot 심화 과정',
       'Spring Boot 3.x 기반 백엔드 개발과 JPA, Security를 심도 있게 학습합니다.',
       u.id, 'DRAFT', 25, 85.00
FROM users u WHERE u.email = 'prof.lee@hanbit.ac.kr' AND u.tenant_id = 'univ_a'
  AND NOT EXISTS (SELECT 1 FROM course WHERE title = 'Spring Boot 심화 과정' AND tenant_id = 'univ_a');

INSERT INTO course (tenant_id, title, description, instructor_id, status, max_students, completion_rate_required)
SELECT 'univ_a', '알고리즘과 자료구조',
       '코딩 테스트 필수 알고리즘과 자료구조 개념을 Java로 구현합니다.',
       u.id, 'PUBLISHED', 45, 80.00
FROM users u WHERE u.email = 'prof.kim@hanbit.ac.kr' AND u.tenant_id = 'univ_a'
  AND NOT EXISTS (SELECT 1 FROM course WHERE title = '알고리즘과 자료구조' AND tenant_id = 'univ_a');

-- univ_b 강좌 2개
INSERT INTO course (tenant_id, title, description, instructor_id, status, max_students, completion_rate_required)
SELECT 'univ_b', '파이썬 기초 프로그래밍',
       '파이썬 언어의 기초 문법부터 실용적인 프로그래밍 패턴까지 배웁니다.',
       u.id, 'PUBLISHED', 50, 75.00
FROM users u WHERE u.email = 'prof.park@mirae.ac.kr' AND u.tenant_id = 'univ_b'
  AND NOT EXISTS (SELECT 1 FROM course WHERE title = '파이썬 기초 프로그래밍' AND tenant_id = 'univ_b');

INSERT INTO course (tenant_id, title, description, instructor_id, status, max_students, completion_rate_required)
SELECT 'univ_b', '머신러닝 입문',
       'scikit-learn을 활용한 머신러닝 기초 이론과 실습을 진행합니다.',
       u.id, 'PUBLISHED', 30, 80.00
FROM users u WHERE u.email = 'prof.park@mirae.ac.kr' AND u.tenant_id = 'univ_b'
  AND NOT EXISTS (SELECT 1 FROM course WHERE title = '머신러닝 입문' AND tenant_id = 'univ_b');

-- ── 강의(lesson) ──
-- Java 기초 프로그래밍 — 5강
INSERT INTO lesson (tenant_id, course_id, title, sort_order, duration_sec, video_url)
SELECT 'univ_a', c.id, '1강. 환경 설정과 Hello World', 1, 1200,
       'https://cdn.learnflow.io/univ_a/java-basics/01.mp4'
FROM course c WHERE c.title = 'Java 기초 프로그래밍' AND c.tenant_id = 'univ_a'
  AND NOT EXISTS (SELECT 1 FROM lesson l WHERE l.course_id = c.id AND l.title = '1강. 환경 설정과 Hello World');

INSERT INTO lesson (tenant_id, course_id, title, sort_order, duration_sec, video_url)
SELECT 'univ_a', c.id, '2강. 변수와 자료형', 2, 1800,
       'https://cdn.learnflow.io/univ_a/java-basics/02.mp4'
FROM course c WHERE c.title = 'Java 기초 프로그래밍' AND c.tenant_id = 'univ_a'
  AND NOT EXISTS (SELECT 1 FROM lesson l WHERE l.course_id = c.id AND l.title = '2강. 변수와 자료형');

INSERT INTO lesson (tenant_id, course_id, title, sort_order, duration_sec, video_url)
SELECT 'univ_a', c.id, '3강. 조건문과 반복문', 3, 2100,
       'https://cdn.learnflow.io/univ_a/java-basics/03.mp4'
FROM course c WHERE c.title = 'Java 기초 프로그래밍' AND c.tenant_id = 'univ_a'
  AND NOT EXISTS (SELECT 1 FROM lesson l WHERE l.course_id = c.id AND l.title = '3강. 조건문과 반복문');

INSERT INTO lesson (tenant_id, course_id, title, sort_order, duration_sec, video_url)
SELECT 'univ_a', c.id, '4강. 배열과 컬렉션', 4, 1800,
       'https://cdn.learnflow.io/univ_a/java-basics/04.mp4'
FROM course c WHERE c.title = 'Java 기초 프로그래밍' AND c.tenant_id = 'univ_a'
  AND NOT EXISTS (SELECT 1 FROM lesson l WHERE l.course_id = c.id AND l.title = '4강. 배열과 컬렉션');

INSERT INTO lesson (tenant_id, course_id, title, sort_order, duration_sec, video_url)
SELECT 'univ_a', c.id, '5강. 클래스와 객체지향', 5, 2400,
       'https://cdn.learnflow.io/univ_a/java-basics/05.mp4'
FROM course c WHERE c.title = 'Java 기초 프로그래밍' AND c.tenant_id = 'univ_a'
  AND NOT EXISTS (SELECT 1 FROM lesson l WHERE l.course_id = c.id AND l.title = '5강. 클래스와 객체지향');

-- 데이터베이스 설계와 SQL — 4강
INSERT INTO lesson (tenant_id, course_id, title, sort_order, duration_sec, video_url)
SELECT 'univ_a', c.id, '1강. 관계형 데이터베이스 개요', 1, 1500,
       'https://cdn.learnflow.io/univ_a/db-sql/01.mp4'
FROM course c WHERE c.title = '데이터베이스 설계와 SQL' AND c.tenant_id = 'univ_a'
  AND NOT EXISTS (SELECT 1 FROM lesson l WHERE l.course_id = c.id AND l.title = '1강. 관계형 데이터베이스 개요');

INSERT INTO lesson (tenant_id, course_id, title, sort_order, duration_sec, video_url)
SELECT 'univ_a', c.id, '2강. SELECT 기본 문법', 2, 2100,
       'https://cdn.learnflow.io/univ_a/db-sql/02.mp4'
FROM course c WHERE c.title = '데이터베이스 설계와 SQL' AND c.tenant_id = 'univ_a'
  AND NOT EXISTS (SELECT 1 FROM lesson l WHERE l.course_id = c.id AND l.title = '2강. SELECT 기본 문법');

INSERT INTO lesson (tenant_id, course_id, title, sort_order, duration_sec, video_url)
SELECT 'univ_a', c.id, '3강. JOIN 이해하기', 3, 2400,
       'https://cdn.learnflow.io/univ_a/db-sql/03.mp4'
FROM course c WHERE c.title = '데이터베이스 설계와 SQL' AND c.tenant_id = 'univ_a'
  AND NOT EXISTS (SELECT 1 FROM lesson l WHERE l.course_id = c.id AND l.title = '3강. JOIN 이해하기');

INSERT INTO lesson (tenant_id, course_id, title, sort_order, duration_sec, video_url)
SELECT 'univ_a', c.id, '4강. 인덱스와 성능 최적화', 4, 1800,
       'https://cdn.learnflow.io/univ_a/db-sql/04.mp4'
FROM course c WHERE c.title = '데이터베이스 설계와 SQL' AND c.tenant_id = 'univ_a'
  AND NOT EXISTS (SELECT 1 FROM lesson l WHERE l.course_id = c.id AND l.title = '4강. 인덱스와 성능 최적화');

-- 웹 프론트엔드 입문 — 4강
INSERT INTO lesson (tenant_id, course_id, title, sort_order, duration_sec, video_url)
SELECT 'univ_a', c.id, '1강. HTML 구조와 태그', 1, 1200,
       'https://cdn.learnflow.io/univ_a/web-frontend/01.mp4'
FROM course c WHERE c.title = '웹 프론트엔드 입문' AND c.tenant_id = 'univ_a'
  AND NOT EXISTS (SELECT 1 FROM lesson l WHERE l.course_id = c.id AND l.title = '1강. HTML 구조와 태그');

INSERT INTO lesson (tenant_id, course_id, title, sort_order, duration_sec, video_url)
SELECT 'univ_a', c.id, '2강. CSS 스타일링 기초', 2, 1800,
       'https://cdn.learnflow.io/univ_a/web-frontend/02.mp4'
FROM course c WHERE c.title = '웹 프론트엔드 입문' AND c.tenant_id = 'univ_a'
  AND NOT EXISTS (SELECT 1 FROM lesson l WHERE l.course_id = c.id AND l.title = '2강. CSS 스타일링 기초');

INSERT INTO lesson (tenant_id, course_id, title, sort_order, duration_sec, video_url)
SELECT 'univ_a', c.id, '3강. JavaScript 입문', 3, 2100,
       'https://cdn.learnflow.io/univ_a/web-frontend/03.mp4'
FROM course c WHERE c.title = '웹 프론트엔드 입문' AND c.tenant_id = 'univ_a'
  AND NOT EXISTS (SELECT 1 FROM lesson l WHERE l.course_id = c.id AND l.title = '3강. JavaScript 입문');

INSERT INTO lesson (tenant_id, course_id, title, sort_order, duration_sec, video_url)
SELECT 'univ_a', c.id, '4강. DOM 조작과 이벤트', 4, 1800,
       'https://cdn.learnflow.io/univ_a/web-frontend/04.mp4'
FROM course c WHERE c.title = '웹 프론트엔드 입문' AND c.tenant_id = 'univ_a'
  AND NOT EXISTS (SELECT 1 FROM lesson l WHERE l.course_id = c.id AND l.title = '4강. DOM 조작과 이벤트');

-- Spring Boot 심화 과정 — 3강 (DRAFT)
INSERT INTO lesson (tenant_id, course_id, title, sort_order, duration_sec, video_url)
SELECT 'univ_a', c.id, '1강. Spring Boot 아키텍처', 1, 1800,
       'https://cdn.learnflow.io/univ_a/spring-boot/01.mp4'
FROM course c WHERE c.title = 'Spring Boot 심화 과정' AND c.tenant_id = 'univ_a'
  AND NOT EXISTS (SELECT 1 FROM lesson l WHERE l.course_id = c.id AND l.title = '1강. Spring Boot 아키텍처');

INSERT INTO lesson (tenant_id, course_id, title, sort_order, duration_sec, video_url)
SELECT 'univ_a', c.id, '2강. JPA와 데이터 접근', 2, 2400,
       'https://cdn.learnflow.io/univ_a/spring-boot/02.mp4'
FROM course c WHERE c.title = 'Spring Boot 심화 과정' AND c.tenant_id = 'univ_a'
  AND NOT EXISTS (SELECT 1 FROM lesson l WHERE l.course_id = c.id AND l.title = '2강. JPA와 데이터 접근');

INSERT INTO lesson (tenant_id, course_id, title, sort_order, duration_sec, video_url)
SELECT 'univ_a', c.id, '3강. Spring Security 설정', 3, 2100,
       'https://cdn.learnflow.io/univ_a/spring-boot/03.mp4'
FROM course c WHERE c.title = 'Spring Boot 심화 과정' AND c.tenant_id = 'univ_a'
  AND NOT EXISTS (SELECT 1 FROM lesson l WHERE l.course_id = c.id AND l.title = '3강. Spring Security 설정');

-- 알고리즘과 자료구조 — 4강
INSERT INTO lesson (tenant_id, course_id, title, sort_order, duration_sec, video_url)
SELECT 'univ_a', c.id, '1강. 시간복잡도와 Big-O', 1, 1500,
       'https://cdn.learnflow.io/univ_a/algorithm/01.mp4'
FROM course c WHERE c.title = '알고리즘과 자료구조' AND c.tenant_id = 'univ_a'
  AND NOT EXISTS (SELECT 1 FROM lesson l WHERE l.course_id = c.id AND l.title = '1강. 시간복잡도와 Big-O');

INSERT INTO lesson (tenant_id, course_id, title, sort_order, duration_sec, video_url)
SELECT 'univ_a', c.id, '2강. 스택과 큐', 2, 1800,
       'https://cdn.learnflow.io/univ_a/algorithm/02.mp4'
FROM course c WHERE c.title = '알고리즘과 자료구조' AND c.tenant_id = 'univ_a'
  AND NOT EXISTS (SELECT 1 FROM lesson l WHERE l.course_id = c.id AND l.title = '2강. 스택과 큐');

INSERT INTO lesson (tenant_id, course_id, title, sort_order, duration_sec, video_url)
SELECT 'univ_a', c.id, '3강. 정렬 알고리즘', 3, 2100,
       'https://cdn.learnflow.io/univ_a/algorithm/03.mp4'
FROM course c WHERE c.title = '알고리즘과 자료구조' AND c.tenant_id = 'univ_a'
  AND NOT EXISTS (SELECT 1 FROM lesson l WHERE l.course_id = c.id AND l.title = '3강. 정렬 알고리즘');

INSERT INTO lesson (tenant_id, course_id, title, sort_order, duration_sec, video_url)
SELECT 'univ_a', c.id, '4강. 트리와 그래프', 4, 2400,
       'https://cdn.learnflow.io/univ_a/algorithm/04.mp4'
FROM course c WHERE c.title = '알고리즘과 자료구조' AND c.tenant_id = 'univ_a'
  AND NOT EXISTS (SELECT 1 FROM lesson l WHERE l.course_id = c.id AND l.title = '4강. 트리와 그래프');

-- 파이썬 기초 프로그래밍 (univ_b) — 4강
INSERT INTO lesson (tenant_id, course_id, title, sort_order, duration_sec, video_url)
SELECT 'univ_b', c.id, '1강. 파이썬 환경 설정', 1, 1200,
       'https://cdn.learnflow.io/univ_b/python-basics/01.mp4'
FROM course c WHERE c.title = '파이썬 기초 프로그래밍' AND c.tenant_id = 'univ_b'
  AND NOT EXISTS (SELECT 1 FROM lesson l WHERE l.course_id = c.id AND l.title = '1강. 파이썬 환경 설정');

INSERT INTO lesson (tenant_id, course_id, title, sort_order, duration_sec, video_url)
SELECT 'univ_b', c.id, '2강. 기본 문법과 자료형', 2, 1800,
       'https://cdn.learnflow.io/univ_b/python-basics/02.mp4'
FROM course c WHERE c.title = '파이썬 기초 프로그래밍' AND c.tenant_id = 'univ_b'
  AND NOT EXISTS (SELECT 1 FROM lesson l WHERE l.course_id = c.id AND l.title = '2강. 기본 문법과 자료형');

INSERT INTO lesson (tenant_id, course_id, title, sort_order, duration_sec, video_url)
SELECT 'univ_b', c.id, '3강. 함수와 모듈', 3, 2100,
       'https://cdn.learnflow.io/univ_b/python-basics/03.mp4'
FROM course c WHERE c.title = '파이썬 기초 프로그래밍' AND c.tenant_id = 'univ_b'
  AND NOT EXISTS (SELECT 1 FROM lesson l WHERE l.course_id = c.id AND l.title = '3강. 함수와 모듈');

INSERT INTO lesson (tenant_id, course_id, title, sort_order, duration_sec, video_url)
SELECT 'univ_b', c.id, '4강. 파일 입출력과 예외처리', 4, 1500,
       'https://cdn.learnflow.io/univ_b/python-basics/04.mp4'
FROM course c WHERE c.title = '파이썬 기초 프로그래밍' AND c.tenant_id = 'univ_b'
  AND NOT EXISTS (SELECT 1 FROM lesson l WHERE l.course_id = c.id AND l.title = '4강. 파일 입출력과 예외처리');

-- 머신러닝 입문 (univ_b) — 3강
INSERT INTO lesson (tenant_id, course_id, title, sort_order, duration_sec, video_url)
SELECT 'univ_b', c.id, '1강. ML 개요와 종류', 1, 1800,
       'https://cdn.learnflow.io/univ_b/ml-intro/01.mp4'
FROM course c WHERE c.title = '머신러닝 입문' AND c.tenant_id = 'univ_b'
  AND NOT EXISTS (SELECT 1 FROM lesson l WHERE l.course_id = c.id AND l.title = '1강. ML 개요와 종류');

INSERT INTO lesson (tenant_id, course_id, title, sort_order, duration_sec, video_url)
SELECT 'univ_b', c.id, '2강. scikit-learn 기초', 2, 2400,
       'https://cdn.learnflow.io/univ_b/ml-intro/02.mp4'
FROM course c WHERE c.title = '머신러닝 입문' AND c.tenant_id = 'univ_b'
  AND NOT EXISTS (SELECT 1 FROM lesson l WHERE l.course_id = c.id AND l.title = '2강. scikit-learn 기초');

INSERT INTO lesson (tenant_id, course_id, title, sort_order, duration_sec, video_url)
SELECT 'univ_b', c.id, '3강. 분류 모델 실습', 3, 2700,
       'https://cdn.learnflow.io/univ_b/ml-intro/03.mp4'
FROM course c WHERE c.title = '머신러닝 입문' AND c.tenant_id = 'univ_b'
  AND NOT EXISTS (SELECT 1 FROM lesson l WHERE l.course_id = c.id AND l.title = '3강. 분류 모델 실습');

-- ── 수강 신청 (enrollment) ──
-- student1@hanbit: Java 기초(ACTIVE), DB(ACTIVE)
INSERT INTO enrollment (tenant_id, course_id, user_id, status, enrolled_at)
SELECT 'univ_a', c.id, u.id, 'ACTIVE', '2026-03-01 09:00:00'
FROM course c, users u
WHERE c.title = 'Java 기초 프로그래밍' AND c.tenant_id = 'univ_a'
  AND u.email = 'student1@hanbit.ac.kr'  AND u.tenant_id = 'univ_a'
ON CONFLICT DO NOTHING;

INSERT INTO enrollment (tenant_id, course_id, user_id, status, enrolled_at)
SELECT 'univ_a', c.id, u.id, 'ACTIVE', '2026-03-05 10:00:00'
FROM course c, users u
WHERE c.title = '데이터베이스 설계와 SQL' AND c.tenant_id = 'univ_a'
  AND u.email = 'student1@hanbit.ac.kr'  AND u.tenant_id = 'univ_a'
ON CONFLICT DO NOTHING;

-- student2@hanbit: Java 기초(ACTIVE), 웹(ACTIVE)
INSERT INTO enrollment (tenant_id, course_id, user_id, status, enrolled_at)
SELECT 'univ_a', c.id, u.id, 'ACTIVE', '2026-03-01 11:00:00'
FROM course c, users u
WHERE c.title = 'Java 기초 프로그래밍' AND c.tenant_id = 'univ_a'
  AND u.email = 'student2@hanbit.ac.kr'  AND u.tenant_id = 'univ_a'
ON CONFLICT DO NOTHING;

INSERT INTO enrollment (tenant_id, course_id, user_id, status, enrolled_at)
SELECT 'univ_a', c.id, u.id, 'ACTIVE', '2026-03-10 14:00:00'
FROM course c, users u
WHERE c.title = '웹 프론트엔드 입문' AND c.tenant_id = 'univ_a'
  AND u.email = 'student2@hanbit.ac.kr'  AND u.tenant_id = 'univ_a'
ON CONFLICT DO NOTHING;

-- student3@hanbit: Java 기초(COMPLETED — 전강 수료)
INSERT INTO enrollment (tenant_id, course_id, user_id, status, enrolled_at, completed_at)
SELECT 'univ_a', c.id, u.id, 'COMPLETED', '2026-02-01 09:00:00', '2026-03-20 18:00:00'
FROM course c, users u
WHERE c.title = 'Java 기초 프로그래밍' AND c.tenant_id = 'univ_a'
  AND u.email = 'student3@hanbit.ac.kr'  AND u.tenant_id = 'univ_a'
ON CONFLICT DO NOTHING;

-- student4@hanbit: DB(ACTIVE), 웹(ACTIVE)
INSERT INTO enrollment (tenant_id, course_id, user_id, status, enrolled_at)
SELECT 'univ_a', c.id, u.id, 'ACTIVE', '2026-03-05 09:30:00'
FROM course c, users u
WHERE c.title = '데이터베이스 설계와 SQL' AND c.tenant_id = 'univ_a'
  AND u.email = 'student4@hanbit.ac.kr'  AND u.tenant_id = 'univ_a'
ON CONFLICT DO NOTHING;

INSERT INTO enrollment (tenant_id, course_id, user_id, status, enrolled_at)
SELECT 'univ_a', c.id, u.id, 'ACTIVE', '2026-03-12 11:00:00'
FROM course c, users u
WHERE c.title = '웹 프론트엔드 입문' AND c.tenant_id = 'univ_a'
  AND u.email = 'student4@hanbit.ac.kr'  AND u.tenant_id = 'univ_a'
ON CONFLICT DO NOTHING;

-- student5@hanbit: 웹(ACTIVE)
INSERT INTO enrollment (tenant_id, course_id, user_id, status, enrolled_at)
SELECT 'univ_a', c.id, u.id, 'ACTIVE', '2026-04-01 10:00:00'
FROM course c, users u
WHERE c.title = '웹 프론트엔드 입문' AND c.tenant_id = 'univ_a'
  AND u.email = 'student5@hanbit.ac.kr'  AND u.tenant_id = 'univ_a'
ON CONFLICT DO NOTHING;

-- student1@mirae: 파이썬(ACTIVE)
INSERT INTO enrollment (tenant_id, course_id, user_id, status, enrolled_at)
SELECT 'univ_b', c.id, u.id, 'ACTIVE', '2026-03-01 09:00:00'
FROM course c, users u
WHERE c.title = '파이썬 기초 프로그래밍' AND c.tenant_id = 'univ_b'
  AND u.email = 'student1@mirae.ac.kr'   AND u.tenant_id = 'univ_b'
ON CONFLICT DO NOTHING;

-- student2@mirae: 파이썬(ACTIVE), ML(ACTIVE)
INSERT INTO enrollment (tenant_id, course_id, user_id, status, enrolled_at)
SELECT 'univ_b', c.id, u.id, 'ACTIVE', '2026-03-03 10:00:00'
FROM course c, users u
WHERE c.title = '파이썬 기초 프로그래밍' AND c.tenant_id = 'univ_b'
  AND u.email = 'student2@mirae.ac.kr'   AND u.tenant_id = 'univ_b'
ON CONFLICT DO NOTHING;

INSERT INTO enrollment (tenant_id, course_id, user_id, status, enrolled_at)
SELECT 'univ_b', c.id, u.id, 'ACTIVE', '2026-04-01 09:00:00'
FROM course c, users u
WHERE c.title = '머신러닝 입문' AND c.tenant_id = 'univ_b'
  AND u.email = 'student2@mirae.ac.kr'   AND u.tenant_id = 'univ_b'
ON CONFLICT DO NOTHING;

-- ── 수강 진도 (progress) ──
-- [student1@hanbit + Java 기초] 3강 시청 (2강 완료, 3강 진행중)
INSERT INTO progress (tenant_id, enrollment_id, lesson_id, watched_sec, completed, last_watched_at)
SELECT 'univ_a', e.id, l.id, 1200, TRUE, '2026-03-02 10:00:00'
FROM enrollment e JOIN course c ON e.course_id = c.id JOIN users u ON e.user_id = u.id
JOIN lesson l ON l.course_id = c.id
WHERE c.title = 'Java 기초 프로그래밍' AND c.tenant_id = 'univ_a'
  AND u.email = 'student1@hanbit.ac.kr' AND l.title = '1강. 환경 설정과 Hello World'
ON CONFLICT DO NOTHING;

INSERT INTO progress (tenant_id, enrollment_id, lesson_id, watched_sec, completed, last_watched_at)
SELECT 'univ_a', e.id, l.id, 1800, TRUE, '2026-03-04 14:00:00'
FROM enrollment e JOIN course c ON e.course_id = c.id JOIN users u ON e.user_id = u.id
JOIN lesson l ON l.course_id = c.id
WHERE c.title = 'Java 기초 프로그래밍' AND c.tenant_id = 'univ_a'
  AND u.email = 'student1@hanbit.ac.kr' AND l.title = '2강. 변수와 자료형'
ON CONFLICT DO NOTHING;

INSERT INTO progress (tenant_id, enrollment_id, lesson_id, watched_sec, completed, last_watched_at)
SELECT 'univ_a', e.id, l.id, 1500, FALSE, '2026-03-06 16:00:00'
FROM enrollment e JOIN course c ON e.course_id = c.id JOIN users u ON e.user_id = u.id
JOIN lesson l ON l.course_id = c.id
WHERE c.title = 'Java 기초 프로그래밍' AND c.tenant_id = 'univ_a'
  AND u.email = 'student1@hanbit.ac.kr' AND l.title = '3강. 조건문과 반복문'
ON CONFLICT DO NOTHING;

-- [student1@hanbit + DB 설계] 2강 완료
INSERT INTO progress (tenant_id, enrollment_id, lesson_id, watched_sec, completed, last_watched_at)
SELECT 'univ_a', e.id, l.id, 1500, TRUE, '2026-03-06 11:00:00'
FROM enrollment e JOIN course c ON e.course_id = c.id JOIN users u ON e.user_id = u.id
JOIN lesson l ON l.course_id = c.id
WHERE c.title = '데이터베이스 설계와 SQL' AND c.tenant_id = 'univ_a'
  AND u.email = 'student1@hanbit.ac.kr' AND l.title = '1강. 관계형 데이터베이스 개요'
ON CONFLICT DO NOTHING;

INSERT INTO progress (tenant_id, enrollment_id, lesson_id, watched_sec, completed, last_watched_at)
SELECT 'univ_a', e.id, l.id, 2100, TRUE, '2026-03-08 14:00:00'
FROM enrollment e JOIN course c ON e.course_id = c.id JOIN users u ON e.user_id = u.id
JOIN lesson l ON l.course_id = c.id
WHERE c.title = '데이터베이스 설계와 SQL' AND c.tenant_id = 'univ_a'
  AND u.email = 'student1@hanbit.ac.kr' AND l.title = '2강. SELECT 기본 문법'
ON CONFLICT DO NOTHING;

-- [student2@hanbit + Java 기초] 1강 완료, 2강 진행중
INSERT INTO progress (tenant_id, enrollment_id, lesson_id, watched_sec, completed, last_watched_at)
SELECT 'univ_a', e.id, l.id, 1200, TRUE, '2026-03-02 15:00:00'
FROM enrollment e JOIN course c ON e.course_id = c.id JOIN users u ON e.user_id = u.id
JOIN lesson l ON l.course_id = c.id
WHERE c.title = 'Java 기초 프로그래밍' AND c.tenant_id = 'univ_a'
  AND u.email = 'student2@hanbit.ac.kr' AND l.title = '1강. 환경 설정과 Hello World'
ON CONFLICT DO NOTHING;

INSERT INTO progress (tenant_id, enrollment_id, lesson_id, watched_sec, completed, last_watched_at)
SELECT 'univ_a', e.id, l.id, 900, FALSE, '2026-03-05 10:00:00'
FROM enrollment e JOIN course c ON e.course_id = c.id JOIN users u ON e.user_id = u.id
JOIN lesson l ON l.course_id = c.id
WHERE c.title = 'Java 기초 프로그래밍' AND c.tenant_id = 'univ_a'
  AND u.email = 'student2@hanbit.ac.kr' AND l.title = '2강. 변수와 자료형'
ON CONFLICT DO NOTHING;

-- [student2@hanbit + 웹] 3강 완료, 4강 진행중
INSERT INTO progress (tenant_id, enrollment_id, lesson_id, watched_sec, completed, last_watched_at)
SELECT 'univ_a', e.id, l.id, 1200, TRUE, '2026-03-11 10:00:00'
FROM enrollment e JOIN course c ON e.course_id = c.id JOIN users u ON e.user_id = u.id
JOIN lesson l ON l.course_id = c.id
WHERE c.title = '웹 프론트엔드 입문' AND c.tenant_id = 'univ_a'
  AND u.email = 'student2@hanbit.ac.kr' AND l.title = '1강. HTML 구조와 태그'
ON CONFLICT DO NOTHING;

INSERT INTO progress (tenant_id, enrollment_id, lesson_id, watched_sec, completed, last_watched_at)
SELECT 'univ_a', e.id, l.id, 1800, TRUE, '2026-03-13 14:00:00'
FROM enrollment e JOIN course c ON e.course_id = c.id JOIN users u ON e.user_id = u.id
JOIN lesson l ON l.course_id = c.id
WHERE c.title = '웹 프론트엔드 입문' AND c.tenant_id = 'univ_a'
  AND u.email = 'student2@hanbit.ac.kr' AND l.title = '2강. CSS 스타일링 기초'
ON CONFLICT DO NOTHING;

INSERT INTO progress (tenant_id, enrollment_id, lesson_id, watched_sec, completed, last_watched_at)
SELECT 'univ_a', e.id, l.id, 2100, TRUE, '2026-03-15 16:00:00'
FROM enrollment e JOIN course c ON e.course_id = c.id JOIN users u ON e.user_id = u.id
JOIN lesson l ON l.course_id = c.id
WHERE c.title = '웹 프론트엔드 입문' AND c.tenant_id = 'univ_a'
  AND u.email = 'student2@hanbit.ac.kr' AND l.title = '3강. JavaScript 입문'
ON CONFLICT DO NOTHING;

INSERT INTO progress (tenant_id, enrollment_id, lesson_id, watched_sec, completed, last_watched_at)
SELECT 'univ_a', e.id, l.id, 1200, FALSE, '2026-03-17 11:00:00'
FROM enrollment e JOIN course c ON e.course_id = c.id JOIN users u ON e.user_id = u.id
JOIN lesson l ON l.course_id = c.id
WHERE c.title = '웹 프론트엔드 입문' AND c.tenant_id = 'univ_a'
  AND u.email = 'student2@hanbit.ac.kr' AND l.title = '4강. DOM 조작과 이벤트'
ON CONFLICT DO NOTHING;

-- [student3@hanbit + Java 기초] 5강 전부 완료 (일괄 삽입)
INSERT INTO progress (tenant_id, enrollment_id, lesson_id, watched_sec, completed, last_watched_at)
SELECT 'univ_a', e.id, l.id, l.duration_sec, TRUE, '2026-03-10 10:00:00'
FROM enrollment e JOIN course c ON e.course_id = c.id JOIN users u ON e.user_id = u.id
JOIN lesson l ON l.course_id = c.id
WHERE c.title = 'Java 기초 프로그래밍' AND c.tenant_id = 'univ_a'
  AND u.email = 'student3@hanbit.ac.kr'
ON CONFLICT DO NOTHING;

-- [student4@hanbit + DB 설계] 1강 완료
INSERT INTO progress (tenant_id, enrollment_id, lesson_id, watched_sec, completed, last_watched_at)
SELECT 'univ_a', e.id, l.id, 1500, TRUE, '2026-03-10 09:00:00'
FROM enrollment e JOIN course c ON e.course_id = c.id JOIN users u ON e.user_id = u.id
JOIN lesson l ON l.course_id = c.id
WHERE c.title = '데이터베이스 설계와 SQL' AND c.tenant_id = 'univ_a'
  AND u.email = 'student4@hanbit.ac.kr' AND l.title = '1강. 관계형 데이터베이스 개요'
ON CONFLICT DO NOTHING;

-- [student5@hanbit + 웹] 1강 진행중
INSERT INTO progress (tenant_id, enrollment_id, lesson_id, watched_sec, completed, last_watched_at)
SELECT 'univ_a', e.id, l.id, 600, FALSE, '2026-04-02 10:00:00'
FROM enrollment e JOIN course c ON e.course_id = c.id JOIN users u ON e.user_id = u.id
JOIN lesson l ON l.course_id = c.id
WHERE c.title = '웹 프론트엔드 입문' AND c.tenant_id = 'univ_a'
  AND u.email = 'student5@hanbit.ac.kr' AND l.title = '1강. HTML 구조와 태그'
ON CONFLICT DO NOTHING;

-- [student1@mirae + 파이썬] 2강 완료, 3강 진행중
INSERT INTO progress (tenant_id, enrollment_id, lesson_id, watched_sec, completed, last_watched_at)
SELECT 'univ_b', e.id, l.id, 1200, TRUE, '2026-03-02 10:00:00'
FROM enrollment e JOIN course c ON e.course_id = c.id JOIN users u ON e.user_id = u.id
JOIN lesson l ON l.course_id = c.id
WHERE c.title = '파이썬 기초 프로그래밍' AND c.tenant_id = 'univ_b'
  AND u.email = 'student1@mirae.ac.kr' AND l.title = '1강. 파이썬 환경 설정'
ON CONFLICT DO NOTHING;

INSERT INTO progress (tenant_id, enrollment_id, lesson_id, watched_sec, completed, last_watched_at)
SELECT 'univ_b', e.id, l.id, 1800, TRUE, '2026-03-04 14:00:00'
FROM enrollment e JOIN course c ON e.course_id = c.id JOIN users u ON e.user_id = u.id
JOIN lesson l ON l.course_id = c.id
WHERE c.title = '파이썬 기초 프로그래밍' AND c.tenant_id = 'univ_b'
  AND u.email = 'student1@mirae.ac.kr' AND l.title = '2강. 기본 문법과 자료형'
ON CONFLICT DO NOTHING;

INSERT INTO progress (tenant_id, enrollment_id, lesson_id, watched_sec, completed, last_watched_at)
SELECT 'univ_b', e.id, l.id, 1000, FALSE, '2026-03-06 11:00:00'
FROM enrollment e JOIN course c ON e.course_id = c.id JOIN users u ON e.user_id = u.id
JOIN lesson l ON l.course_id = c.id
WHERE c.title = '파이썬 기초 프로그래밍' AND c.tenant_id = 'univ_b'
  AND u.email = 'student1@mirae.ac.kr' AND l.title = '3강. 함수와 모듈'
ON CONFLICT DO NOTHING;

-- [student2@mirae + 파이썬] 1강 완료
INSERT INTO progress (tenant_id, enrollment_id, lesson_id, watched_sec, completed, last_watched_at)
SELECT 'univ_b', e.id, l.id, 1200, TRUE, '2026-03-04 10:00:00'
FROM enrollment e JOIN course c ON e.course_id = c.id JOIN users u ON e.user_id = u.id
JOIN lesson l ON l.course_id = c.id
WHERE c.title = '파이썬 기초 프로그래밍' AND c.tenant_id = 'univ_b'
  AND u.email = 'student2@mirae.ac.kr' AND l.title = '1강. 파이썬 환경 설정'
ON CONFLICT DO NOTHING;

-- [student2@mirae + 머신러닝] 1강 완료
INSERT INTO progress (tenant_id, enrollment_id, lesson_id, watched_sec, completed, last_watched_at)
SELECT 'univ_b', e.id, l.id, 1800, TRUE, '2026-04-02 14:00:00'
FROM enrollment e JOIN course c ON e.course_id = c.id JOIN users u ON e.user_id = u.id
JOIN lesson l ON l.course_id = c.id
WHERE c.title = '머신러닝 입문' AND c.tenant_id = 'univ_b'
  AND u.email = 'student2@mirae.ac.kr' AND l.title = '1강. ML 개요와 종류'
ON CONFLICT DO NOTHING;

-- ── 진도 집계 요약 (progress_summary) ──
-- student1@hanbit + Java: 5강 중 2강 완료 = 40%
INSERT INTO progress_summary (tenant_id, enrollment_id, total_lessons, completed_lessons, completion_rate, last_updated_at)
SELECT 'univ_a', e.id, 5, 2, 40.00, NOW()
FROM enrollment e JOIN course c ON e.course_id = c.id JOIN users u ON e.user_id = u.id
WHERE c.title = 'Java 기초 프로그래밍' AND c.tenant_id = 'univ_a'
  AND u.email = 'student1@hanbit.ac.kr'
ON CONFLICT (tenant_id, enrollment_id) DO NOTHING;

-- student1@hanbit + DB: 4강 중 2강 완료 = 50%
INSERT INTO progress_summary (tenant_id, enrollment_id, total_lessons, completed_lessons, completion_rate, last_updated_at)
SELECT 'univ_a', e.id, 4, 2, 50.00, NOW()
FROM enrollment e JOIN course c ON e.course_id = c.id JOIN users u ON e.user_id = u.id
WHERE c.title = '데이터베이스 설계와 SQL' AND c.tenant_id = 'univ_a'
  AND u.email = 'student1@hanbit.ac.kr'
ON CONFLICT (tenant_id, enrollment_id) DO NOTHING;

-- student2@hanbit + Java: 5강 중 1강 완료 = 20%
INSERT INTO progress_summary (tenant_id, enrollment_id, total_lessons, completed_lessons, completion_rate, last_updated_at)
SELECT 'univ_a', e.id, 5, 1, 20.00, NOW()
FROM enrollment e JOIN course c ON e.course_id = c.id JOIN users u ON e.user_id = u.id
WHERE c.title = 'Java 기초 프로그래밍' AND c.tenant_id = 'univ_a'
  AND u.email = 'student2@hanbit.ac.kr'
ON CONFLICT (tenant_id, enrollment_id) DO NOTHING;

-- student2@hanbit + 웹: 4강 중 3강 완료 = 75%
INSERT INTO progress_summary (tenant_id, enrollment_id, total_lessons, completed_lessons, completion_rate, last_updated_at)
SELECT 'univ_a', e.id, 4, 3, 75.00, NOW()
FROM enrollment e JOIN course c ON e.course_id = c.id JOIN users u ON e.user_id = u.id
WHERE c.title = '웹 프론트엔드 입문' AND c.tenant_id = 'univ_a'
  AND u.email = 'student2@hanbit.ac.kr'
ON CONFLICT (tenant_id, enrollment_id) DO NOTHING;

-- student3@hanbit + Java: 5강 전부 완료 = 100%
INSERT INTO progress_summary (tenant_id, enrollment_id, total_lessons, completed_lessons, completion_rate, last_updated_at)
SELECT 'univ_a', e.id, 5, 5, 100.00, NOW()
FROM enrollment e JOIN course c ON e.course_id = c.id JOIN users u ON e.user_id = u.id
WHERE c.title = 'Java 기초 프로그래밍' AND c.tenant_id = 'univ_a'
  AND u.email = 'student3@hanbit.ac.kr'
ON CONFLICT (tenant_id, enrollment_id) DO NOTHING;

-- student4@hanbit + DB: 4강 중 1강 완료 = 25%
INSERT INTO progress_summary (tenant_id, enrollment_id, total_lessons, completed_lessons, completion_rate, last_updated_at)
SELECT 'univ_a', e.id, 4, 1, 25.00, NOW()
FROM enrollment e JOIN course c ON e.course_id = c.id JOIN users u ON e.user_id = u.id
WHERE c.title = '데이터베이스 설계와 SQL' AND c.tenant_id = 'univ_a'
  AND u.email = 'student4@hanbit.ac.kr'
ON CONFLICT (tenant_id, enrollment_id) DO NOTHING;

-- student4@hanbit + 웹: 4강 중 0강 완료 = 0%
INSERT INTO progress_summary (tenant_id, enrollment_id, total_lessons, completed_lessons, completion_rate, last_updated_at)
SELECT 'univ_a', e.id, 4, 0, 0.00, NOW()
FROM enrollment e JOIN course c ON e.course_id = c.id JOIN users u ON e.user_id = u.id
WHERE c.title = '웹 프론트엔드 입문' AND c.tenant_id = 'univ_a'
  AND u.email = 'student4@hanbit.ac.kr'
ON CONFLICT (tenant_id, enrollment_id) DO NOTHING;

-- student5@hanbit + 웹: 4강 중 0강 완료 = 0%
INSERT INTO progress_summary (tenant_id, enrollment_id, total_lessons, completed_lessons, completion_rate, last_updated_at)
SELECT 'univ_a', e.id, 4, 0, 0.00, NOW()
FROM enrollment e JOIN course c ON e.course_id = c.id JOIN users u ON e.user_id = u.id
WHERE c.title = '웹 프론트엔드 입문' AND c.tenant_id = 'univ_a'
  AND u.email = 'student5@hanbit.ac.kr'
ON CONFLICT (tenant_id, enrollment_id) DO NOTHING;

-- student1@mirae + 파이썬: 4강 중 2강 완료 = 50%
INSERT INTO progress_summary (tenant_id, enrollment_id, total_lessons, completed_lessons, completion_rate, last_updated_at)
SELECT 'univ_b', e.id, 4, 2, 50.00, NOW()
FROM enrollment e JOIN course c ON e.course_id = c.id JOIN users u ON e.user_id = u.id
WHERE c.title = '파이썬 기초 프로그래밍' AND c.tenant_id = 'univ_b'
  AND u.email = 'student1@mirae.ac.kr'
ON CONFLICT (tenant_id, enrollment_id) DO NOTHING;

-- student2@mirae + 파이썬: 4강 중 1강 완료 = 25%
INSERT INTO progress_summary (tenant_id, enrollment_id, total_lessons, completed_lessons, completion_rate, last_updated_at)
SELECT 'univ_b', e.id, 4, 1, 25.00, NOW()
FROM enrollment e JOIN course c ON e.course_id = c.id JOIN users u ON e.user_id = u.id
WHERE c.title = '파이썬 기초 프로그래밍' AND c.tenant_id = 'univ_b'
  AND u.email = 'student2@mirae.ac.kr'
ON CONFLICT (tenant_id, enrollment_id) DO NOTHING;

-- student2@mirae + 머신러닝: 3강 중 1강 완료 = 33.33%
INSERT INTO progress_summary (tenant_id, enrollment_id, total_lessons, completed_lessons, completion_rate, last_updated_at)
SELECT 'univ_b', e.id, 3, 1, 33.33, NOW()
FROM enrollment e JOIN course c ON e.course_id = c.id JOIN users u ON e.user_id = u.id
WHERE c.title = '머신러닝 입문' AND c.tenant_id = 'univ_b'
  AND u.email = 'student2@mirae.ac.kr'
ON CONFLICT (tenant_id, enrollment_id) DO NOTHING;
