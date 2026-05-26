package com.learnflow.domain.progress;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;

@Slf4j
@Component
@RequiredArgsConstructor
public class ProgressSummaryBatch {

    private final ProgressMapper progressMapper;

    /** 매일 새벽 2시 — 전체 재집계 */
    @Scheduled(cron = "0 0 2 * * *")
    @Transactional
    public void rebuildFullSummary() {
        log.info("[Batch] 전체 진도 요약 재집계 시작");
        long start = System.currentTimeMillis();

        progressMapper.rebuildSummaryAll();

        long elapsed = System.currentTimeMillis() - start;
        log.info("[Batch] 전체 진도 요약 재집계 완료 - {}ms", elapsed);
    }

    /** 매 1시간 — 최근 변경분 증분 갱신 */
    @Scheduled(cron = "0 0 * * * *")
    @Transactional
    public void incrementalUpdate() {
        LocalDateTime since = LocalDateTime.now().minusHours(1);
        log.debug("[Batch] 증분 진도 집계 시작 - since={}", since);

        progressMapper.upsertSummaryAfter(since);

        log.debug("[Batch] 증분 진도 집계 완료");
    }
}
