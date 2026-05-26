package com.learnflow.domain.user;

import com.learnflow.global.response.ApiResponse;
import com.learnflow.global.security.JwtProvider;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import lombok.*;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {

    private final UserMapper      userMapper;
    private final JwtProvider     jwtProvider;
    private final PasswordEncoder passwordEncoder;

    @PostMapping("/login")
    public ApiResponse<LoginResponse> login(@Valid @RequestBody LoginRequest request) {
        User user = userMapper.findByEmailAndTenant(request.getEmail(), request.getTenantId())
            .orElseThrow(() -> new BadCredentialsException("이메일 또는 비밀번호가 올바르지 않습니다."));

        if (!passwordEncoder.matches(request.getPassword(), user.getPassword())) {
            throw new BadCredentialsException("이메일 또는 비밀번호가 올바르지 않습니다.");
        }

        String token = jwtProvider.createAccessToken(
            user.getId(), user.getTenantId(), user.getRoleName()
        );

        return ApiResponse.ok(new LoginResponse(token, user.getName(), user.getTenantId(), user.getRoleName()));
    }

    @Getter @Setter
    public static class LoginRequest {
        @Email @NotBlank private String email;
        @NotBlank         private String password;
        @NotBlank         private String tenantId;
    }

    @Getter @AllArgsConstructor
    public static class LoginResponse {
        private final String accessToken;
        private final String name;
        private final String tenantId;
        private final String role;
    }
}
