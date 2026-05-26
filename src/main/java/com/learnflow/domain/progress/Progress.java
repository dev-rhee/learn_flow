package com.learnflow.domain.progress;

import lombok.*;
import java.time.LocalDateTime;

@Getter @Builder @NoArgsConstructor @AllArgsConstructor
public class Progress {
    private Long          id;
    private String        tenantId;
    private Long          enrollmentId;
    private Long          lessonId;
    private String        lessonTitle;
    private Integer       watchedSec;
    private Boolean       completed;
    private LocalDateTime lastWatchedAt;
}
