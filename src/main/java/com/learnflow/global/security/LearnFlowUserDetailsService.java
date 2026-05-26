package com.learnflow.global.security;

import com.learnflow.domain.user.User;
import com.learnflow.domain.user.UserMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class LearnFlowUserDetailsService implements UserDetailsService {

    private final UserMapper userMapper;

    @Override
    public UserDetails loadUserByUsername(String username) throws UsernameNotFoundException {
        String[] parts = username.split(":");
        if (parts.length != 2) {
            throw new UsernameNotFoundException("잘못된 username 형식: " + username);
        }

        Long   userId   = Long.valueOf(parts[0]);
        String tenantId = parts[1];

        User user = userMapper.findByIdAndTenant(userId, tenantId)
            .orElseThrow(() ->
                new UsernameNotFoundException("사용자를 찾을 수 없습니다: " + username)
            );

        return UserPrincipal.builder()
            .userId(user.getId())
            .tenantId(user.getTenantId())
            .email(user.getEmail())
            .password(user.getPassword())
            .roleName(user.getRoleName())
            .permissions(user.getPermissions())
            .build();
    }
}
