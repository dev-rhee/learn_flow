package com.learnflow.domain.course;

import com.learnflow.global.response.ApiResponse;
import com.learnflow.global.security.UserPrincipal;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/courses")
@RequiredArgsConstructor
public class CourseController {

    private final CourseService courseService;

    @GetMapping
    public ApiResponse<List<Course>> list() {
        return ApiResponse.ok(courseService.getCourses());
    }

    @GetMapping("/{id}")
    public ApiResponse<Course> detail(@PathVariable Long id) {
        return ApiResponse.ok(courseService.getCourse(id));
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public ApiResponse<Course> create(
        @Valid @RequestBody CourseRequest request,
        @AuthenticationPrincipal UserPrincipal principal
    ) {
        return ApiResponse.ok(courseService.createCourse(request, principal));
    }

    @PutMapping("/{id}")
    public ApiResponse<Course> update(
        @PathVariable Long id,
        @Valid @RequestBody CourseRequest request
    ) {
        return ApiResponse.ok(courseService.updateCourse(id, request));
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable Long id) {
        courseService.deleteCourse(id);
    }
}
