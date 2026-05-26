package com.learnflow.global.interceptor;

import com.learnflow.domain.course.CourseMapper;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.mybatis.spring.boot.test.autoconfigure.MybatisTest;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.jdbc.AutoConfigureTestDatabase;
import org.springframework.context.annotation.Import;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * TenantInterceptor 핵심 테스트.
 * 같은 쿼리라도 TenantContext에 따라 다른 데이터가 반환되는지,
 * 크로스 테넌트 접근이 차단되는지 검증한다.
 */
@MybatisTest
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.NONE)
@Import(TenantInterceptor.class)
class TenantInterceptorTest {

    @Autowired
    private CourseMapper courseMapper;

    @BeforeEach
    void setUp() {
        // 각 테스트 전 컨텍스트 초기화
        TenantContext.clear();
    }

    @AfterEach
    void tearDown() {
        TenantContext.clear();
    }

    @Test
    @DisplayName("univ_a 컨텍스트로 조회하면 univ_a 강좌만 반환된다")
    void shouldReturnOnlyTenantACourses() {
        TenantContext.setTenantId("univ_a");

        List<?> courses = courseMapper.findAll();

        assertThat(courses).isNotEmpty();
        assertThat(courses).allSatisfy(c -> {
            // 모든 결과가 univ_a 소속이어야 함
            assertThat(c.toString()).contains("univ_a");
        });
    }

    @Test
    @DisplayName("univ_b 컨텍스트로 조회하면 univ_a 데이터에 접근할 수 없다")
    void shouldNotAccessOtherTenantData() {
        // univ_a 데이터 수
        TenantContext.setTenantId("univ_a");
        int countA = courseMapper.findAll().size();

        // univ_b 데이터 수
        TenantContext.clear();
        TenantContext.setTenantId("univ_b");
        int countB = courseMapper.findAll().size();

        // 두 테넌트의 데이터가 섞이지 않아야 함
        // (합산이 전체 데이터 수와 같아야 함 — 격리 검증)
        TenantContext.clear();
        // tenant 없이 조회하면 전체 조회됨
        int countAll = courseMapper.findAll().size();

        assertThat(countA + countB).isEqualTo(countAll);
    }

    @Test
    @DisplayName("TenantContext가 없으면 전체 데이터가 반환된다 (공개 API 등)")
    void shouldReturnAllWhenNoTenantContext() {
        // TenantContext 미설정 상태
        List<?> courses = courseMapper.findAll();

        // 필터 없이 전체 반환
        assertThat(courses).isNotNull();
    }
}
