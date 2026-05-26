package com.learnflow.domain.chatbot;

import lombok.*;

import java.util.List;

@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ChatStreamRequest {

    private String question;


    private List<ChatMessage> history;
}