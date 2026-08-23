    package com.campussync.campussync_backend.service;

    import org.springframework.security.crypto.password.PasswordEncoder;
    import org.springframework.stereotype.Service;

    import com.campussync.campussync_backend.dto.LoginRequest;
    import com.campussync.campussync_backend.entity.User;
    import com.campussync.campussync_backend.repository.UserRepository;
    import com.campussync.campussync_backend.dto.LoginResponse; 
import com.campussync.campussync_backend.enums.UserStatus;
import com.campussync.campussync_backend.exception.InvalidCredentialsException;
import com.campussync.campussync_backend.exception.AccountNotActiveException;
    @Service
    public class AuthService {

        private final UserRepository userRepository;
        private final PasswordEncoder passwordEncoder;
        private final JwtService jwtService;

        public AuthService(
                UserRepository userRepository,
                PasswordEncoder passwordEncoder,
            JwtService jwtService) {

            this.userRepository = userRepository;
            this.passwordEncoder = passwordEncoder;
            this.jwtService=jwtService;
        }

        public LoginResponse login(LoginRequest request) {

            User user = userRepository.findByEmail(request.getEmail())
                    .orElseThrow(() ->
    new InvalidCredentialsException(
        "Invalid email or password"
    ));
                           if (user.getStatus() != UserStatus.ACTIVE) {
    throw new AccountNotActiveException(
        "Account is not active"
    );
}
            if (!passwordEncoder.matches(
                    request.getPassword(),
                    user.getPassword())) {
throw new InvalidCredentialsException(
    "Invalid email or password"
);
            
}
        String token=jwtService.generateToken(user.getEmail(),
        user.getRole().name());
        
        return new LoginResponse(token,user.getId(),user.getName(),user.getEmail(),user.getRole().name(),user.isFirstLogin());

    }
    }
