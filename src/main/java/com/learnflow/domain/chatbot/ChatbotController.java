package com.learnflow.domain.chatbot;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.http.codec.ServerSentEvent;
import org.springframework.web.bind.annotation.*;
import reactor.core.publisher.Flux;
import java.util.Map;

@Slf4j
@RestController
@RequestMapping("/api/chatbot")
@RequiredArgsConstructor
public class ChatbotController {

    private final ChatbotService chatbotService;

    @PostMapping(value = "/stream", produces = MediaType.TEXT_EVENT_STREAM_VALUE)
    public Flux<ServerSentEvent<String>> stream(@Valid @RequestBody ChatRequest request) {
        log.info("[CHATBOT] stream: question={}", request.getQuestion());
        return chatbotService.streamChat(request.getQuestion(), request.getHistory())
                .map(t -> ServerSentEvent.<String>builder()
                        .event("message")
                        .data(t)
                        .build())
                .concatWith(Flux.just(
                        ServerSentEvent.<String>builder().event("done").data("[DONE]").build()
                ));
    }

    @PostMapping("/index-db")
    public ResponseEntity<Map<String, Object>> indexDb(@Valid @RequestBody DbIndexRequest request) {
        log.info("[CHATBOT] index-db: table={}", request.getTableName());
        return ResponseEntity.ok(chatbotService.indexDbTable(request));
    }
}