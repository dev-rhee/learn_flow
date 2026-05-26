package com.learnflow.domain.chatbot;

import com.fasterxml.jackson.annotation.JsonProperty;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import lombok.*;

import java.util.List;

@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class DbIndexRequest {

    @NotBlank
    @JsonProperty("table_name")
    private String tableName;

    @NotEmpty
    @JsonProperty("text_columns")
    private List<String> textColumns;

    @Builder.Default
    @JsonProperty("id_column")
    private String idColumn = "id";
}