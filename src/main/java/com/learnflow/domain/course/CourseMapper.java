package com.learnflow.domain.course;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;
import java.util.Optional;

@Mapper
public interface CourseMapper {

    // tenant_id 조건은 TenantInterceptor가 자동 주입
    List<Course> findAll();

    Optional<Course> findById(@Param("id") Long id);

    void insert(Course course);

    void update(Course course);

    void deleteById(@Param("id") Long id);
}
