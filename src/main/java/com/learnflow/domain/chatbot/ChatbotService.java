package com.learnflow.domain.chatbot;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.core.ParameterizedTypeReference;
import org.springframework.http.codec.ServerSentEvent;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;
import reactor.core.publisher.Flux;
import java.util.*;

@Slf4j
@Service
@RequiredArgsConstructor
public class ChatbotService {

    private final WebClient ragWebClient;

    public Flux<String> streamChat(String question, List<ChatMessage> history) {
        long start = System.currentTimeMillis();

        Map<String, Object> body = new HashMap<>();
        body.put("question", question);
        body.put("history", history);

        return ragWebClient.post()
                .uri("/chat/stream")
                .bodyValue(body)
                .retrieve()
                .bodyToFlux(new ParameterizedTypeReference<ServerSentEvent<String>>() {})
                .filter(event -> event.data() != null && !event.data().equals("[DONE]"))
                .map(ServerSentEvent::data)
                .filter(t -> !t.isEmpty())
                .doOnComplete(() -> log.info(
                        "[RAG_RESPONSE_COMPLETE] question={} duration={}ms",
                        question, System.currentTimeMillis() - start
                ))
                .doOnError(e -> log.error(
                        "[RAG_STREAM_ERROR] question={} error={}",
                        question, e.getMessage(), e
                ))
                .onErrorReturn("[오류] RAG 서버 연결 실패");
    }

    public Map<String, Object> indexDbTable(DbIndexRequest request) {
        log.info("[RAG_INDEX_DB] table={} columns={}", request.getTableName(), request.getTextColumns());

        Map<String, Object> body = new HashMap<>();
        body.put("table_name", request.getTableName());
        body.put("text_columns", request.getTextColumns());
        body.put("id_column", request.getIdColumn());

        Map<String, Object> result = ragWebClient.post()
                .uri("/documents/index-db")
                .bodyValue(body)
                .retrieve()
                .bodyToMono(new ParameterizedTypeReference<Map<String, Object>>() {})
                .doOnError(e -> log.error(
                        "[RAG_INDEX_DB_ERROR] table={} error={}",
                        request.getTableName(), e.getMessage(), e
                ))
                .block();

        log.info("[RAG_INDEX_DB_COMPLETE] table={} result={}", request.getTableName(), result);
        return result;
    }
}