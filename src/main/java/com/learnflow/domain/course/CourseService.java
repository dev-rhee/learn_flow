package com.learnflow.domain.course;

import com.learnflow.global.exception.NotFoundException;
import com.learnflow.global.interceptor.TenantContext;
import com.learnflow.global.security.UserPrincipal;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

import static com.learnflow.global.security.Permission.*;

@Slf4j
@Service
@RequiredArgsConstructor
public class CourseService {

    private final CourseMapper courseMapper;

    @PreAuthorize("hasAuthority('" + COURSE_READ + "')")
    @Transactional(readOnly = true)
    public List<Course> getCourses() {
        // TenantInterceptor가 tenant_id 조건을 자동 주입하므로
        // 서비스 레이어에서 tenantId를 명시할 필요 없음
        return courseMapper.findAll();
    }

    @PreAuthorize("hasAuthority('" + COURSE_READ + "')")
    @Transactional(readOnly = true)
    public Course getCourse(Long id) {
        return courseMapper.findById(id)
            .orElseThrow(() -> new NotFoundException("강좌를 찾을 수 없습니다: " + id));
    }

    @PreAuthorize("hasAuthority('" + COURSE_WRITE + "')")
    @Transactional
    public Course createCourse(CourseRequest request, UserPrincipal principal) {
        Course course = Course.builder()
            .tenantId(TenantContext.getTenantId())
            .title(request.getTitle())
            .description(request.getDescription())
            .instructorId(principal.getUserId())
            .status("DRAFT")
            .maxStudents(request.getMaxStudents())
            .completionRateRequired(request.getCompletionRateRequired() != null
                ? request.getCompletionRateRequired() : 80.0)
            .build();

        courseMapper.insert(course);
        log.info("[Course] 강좌 생성 - tenantId={}, courseId={}, title={}",
            principal.getTenantId(), course.getId(), course.getTitle());

        return courseMapper.findById(course.getId())
            .orElseThrow(() -> new NotFoundException("강좌 생성 후 조회 실패"));
    }

    @PreAuthorize("hasAuthority('" + COURSE_WRITE + "')")
    @Transactional
    public Course updateCourse(Long id, CourseRequest request) {
        Course existing = courseMapper.findById(id)
            .orElseThrow(() -> new NotFoundException("강좌를 찾을 수 없습니다: " + id));

        Course updated = Course.builder()
            .id(existing.getId())
            .tenantId(existing.getTenantId())
            .title(request.getTitle())
            .description(request.getDescription())
            .instructorId(existing.getInstructorId())
            .status(request.getStatus() != null ? request.getStatus() : existing.getStatus())
            .maxStudents(request.getMaxStudents())
            .completionRateRequired(request.getCompletionRateRequired() != null
                ? request.getCompletionRateRequired() : existing.getCompletionRateRequired())
            .build();

        courseMapper.update(updated);
        return courseMapper.findById(id).orElseThrow();
    }

    @PreAuthorize("hasAuthority('" + COURSE_DELETE + "')")
    @Transactional
    public void deleteCourse(Long id) {
        courseMapper.findById(id)
            .orElseThrow(() -> new NotFoundException("강좌를 찾을 수 없습니다: " + id));
        courseMapper.deleteById(id);
    }
}
