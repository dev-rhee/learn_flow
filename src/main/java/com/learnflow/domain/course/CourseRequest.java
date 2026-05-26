package com.learnflow.domain.course;

import jakarta.validation.constraints.NotBlank;
import lombok.*;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class CourseRequest {

    @NotBlank(message = "강좌명은 필수입니다.")
    private String title;

    private String  description;
    private Integer maxStudents;
    private Double  completionRateRequired;
    private String  status;
}
