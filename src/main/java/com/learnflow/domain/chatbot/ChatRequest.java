package com.learnflow.domain.chatbot;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.util.ArrayList;
import java.util.List;

@Getter
@Setter
@NoArgsConstructor
public class ChatRequest {

    @NotBlank
    @Size(max = 2000, message = "질문은 2000자 이하로 입력해주세요.")
    private String question;

    private String sessionId;

    @Size(max = 20, message = "대화 히스토리는 최대 20개까지 허용됩니다.")
    private List<ChatMessage> history = new ArrayList<>();
}