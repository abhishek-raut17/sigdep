package tech.commit.sigdep.gatewayproxy.handlers.user;

import org.springframework.stereotype.Component;
import org.springframework.web.reactive.function.server.ServerRequest;
import org.springframework.web.reactive.function.server.ServerResponse;

import reactor.core.publisher.Mono;

@Component
public class UserReadHandler {
    
    public Mono<ServerResponse> getUserById(ServerRequest request) {

        // Logic to get user by ID
        // This is a placeholder implementation
        return ServerResponse
            .ok()
            .bodyValue("User with ID: " + request.pathVariable("id"));
    }
}
