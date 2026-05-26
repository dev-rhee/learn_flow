package com.learnflow.domain.progress;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Mapper
public interface ProgressMapper {

    List<Progress> findByEnrollmentId(@Param("enrollmentId") Long enrollmentId);

    Optional<Progress> findByEnrollmentAndLesson(
        @Param("enrollmentId") Long enrollmentId,
        @Param("lessonId") Long lessonId
    );

    void upsertProgress(Progress progress);

    // 요약 테이블 조회 (배치 사전 집계된 데이터 — 빠른 응답 보장)
    Optional<ProgressSummary> findSummaryByEnrollmentId(@Param("enrollmentId") Long enrollmentId);

    List<ProgressSummary> findSummaryByCourseId(@Param("courseId") Long courseId);

    // 배치 스케줄러용: 전체 재집계
    void rebuildSummaryAll();

    // 배치 스케줄러용: 증분 갱신 (최근 변경분만)
    void upsertSummaryAfter(@Param("since") LocalDateTime since);
}
