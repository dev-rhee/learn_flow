package com.learnflow.domain.course;

import lombok.*;
import java.time.LocalDateTime;

@Getter @Builder @NoArgsConstructor @AllArgsConstructor
public class Course {
    private Long          id;
    private String        tenantId;
    private String        title;
    private String        description;
    private Long          instructorId;
    private String        instructorName;
    private String        status;
    private Integer       maxStudents;
    private Double        completionRateRequired;
    private LocalDateTime createdAt;
}
