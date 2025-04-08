package tech.commit.sigdep.gatewayproxy.handlers.task;

import org.springframework.stereotype.Component;
import org.springframework.web.reactive.function.server.ServerRequest;
import org.springframework.web.reactive.function.server.ServerResponse;

import reactor.core.publisher.Mono;

@Component
public class TaskReadHandler {
    
    public Mono<ServerResponse> getTaskById(ServerRequest request) {

        // Logic to get task by ID
        // This is a placeholder implementation
        return ServerResponse
            .ok()
            .bodyValue("Task with ID: " + request.pathVariable("id"));
    }
}
