package com.learnflow;

import com.learnflow.domain.chatbot.ChatbotService;
import com.learnflow.domain.chatbot.DbIndexRequest;
import jakarta.annotation.PostConstruct;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.ApplicationRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;
import org.springframework.scheduling.annotation.EnableScheduling;
import org.springframework.security.core.context.SecurityContextHolder;

import java.util.List;

@Slf4j
@SpringBootApplication
@EnableScheduling
public class LearnFlowApplication {
    public static void main(String[] args) {
        SpringApplication.run(LearnFlowApplication.class, args);
    }

    // SSE async dispatch 시 보안 컨텍스트가 자식 스레드에 상속되도록 설정
    @PostConstruct
    public void initSecurityContextStrategy() {
        SecurityContextHolder.setStrategyName(SecurityContextHolder.MODE_INHERITABLETHREADLOCAL);
    }

    @Bean
    public ApplicationRunner indexOnStartup(ChatbotService chatbotService) {
        DbIndexRequest dbIndexRequest = new DbIndexRequest();
        dbIndexRequest.setTableName("course");
        dbIndexRequest.setTextColumns( List.of("title", "description", "instructor_id"));

        return args -> {
            try {
                chatbotService.indexDbTable(
                       dbIndexRequest
                );
            } catch (Exception e) {
                log.warn("[Startup] RAG 인덱싱 실패 (서비스는 계속 실행): {}", e.getMessage());
            }
        };
    }
}
