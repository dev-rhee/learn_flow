package com.learnflow.domain.enrollment;

import lombok.*;
import java.time.LocalDateTime;

@Getter @Builder @NoArgsConstructor @AllArgsConstructor
public class Enrollment {
    private Long          id;
    private String        tenantId;
    private Long          courseId;
    private String        courseTitle;
    private Long          userId;
    private String        userName;
    private String        status;
    private LocalDateTime enrolledAt;
    private LocalDateTime completedAt;
}
