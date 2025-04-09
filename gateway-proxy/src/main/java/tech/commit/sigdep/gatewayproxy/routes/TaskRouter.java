package tech.commit.sigdep.gatewayproxy.routes;

import static org.springframework.web.reactive.function.server.RouterFunctions.route;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.reactive.function.server.RouterFunction;
import org.springframework.web.reactive.function.server.ServerResponse;

import tech.commit.sigdep.gatewayproxy.handlers.task.TaskReadHandler;
import tech.commit.sigdep.gatewayproxy.utils.CommonUtils.Path;

@Configuration
public class TaskRouter {

    private final TaskReadHandler handler;

    public TaskRouter(TaskReadHandler handler) {
        this.handler = handler;
    }
    
    @Bean(name = "taskRoutes")
    public RouterFunction<ServerResponse> taskRoutes() {

        return route()
                .GET(Path.ID, handler::getTaskById)
                .build();
    }
}
