package com.learnflow.domain.progress;

import lombok.*;
import java.time.LocalDateTime;

@Getter @Builder @NoArgsConstructor @AllArgsConstructor
public class ProgressSummary {
    private Long          id;
    private String        tenantId;
    private Long          enrollmentId;
    private String        studentName;
    private String        courseTitle;
    private Integer       totalLessons;
    private Integer       completedLessons;
    private Double        completionRate;
    private LocalDateTime lastUpdatedAt;
}
