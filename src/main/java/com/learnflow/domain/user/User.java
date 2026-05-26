package com.learnflow.domain.user;

import lombok.*;

import java.util.Set;

@Getter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class User {
    private Long   id;
    private String tenantId;
    private String email;
    private String password;
    private String name;
    private String roleName;
    private Set<String> permissions;
    private boolean active;
}
