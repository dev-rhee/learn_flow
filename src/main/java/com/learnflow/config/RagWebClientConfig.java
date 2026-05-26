package com.learnflow.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.reactive.function.client.WebClient;

@Configuration
public class RagWebClientConfig {

    @Value("${rag.server.url}")
    private String ragServerUrl;

    @Bean
    public WebClient ragWebClient() {
        return WebClient.builder()
                .baseUrl(ragServerUrl)
                .defaultHeader("Content-Type", "application/json")
                .build();
    }
}
