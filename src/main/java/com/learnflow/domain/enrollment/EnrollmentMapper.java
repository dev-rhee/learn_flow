package com.learnflow.domain.enrollment;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;
import java.util.Optional;

@Mapper
public interface EnrollmentMapper {

    List<Enrollment> findByUserId(@Param("userId") Long userId);

    List<Enrollment> findByCourseId(@Param("courseId") Long courseId);

    Optional<Enrollment> findById(@Param("id") Long id);

    Optional<Enrollment> findByUserAndCourse(
        @Param("userId") Long userId,
        @Param("courseId") Long courseId
    );

    void insert(Enrollment enrollment);

    void updateStatus(@Param("id") Long id, @Param("status") String status);

    int countActiveByCourse(@Param("courseId") Long courseId);
}
