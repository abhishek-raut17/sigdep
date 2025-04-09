package tech.commit.sigdep.gatewayproxy.routes;

import static org.springframework.web.reactive.function.server.RouterFunctions.route;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.reactive.function.server.RouterFunction;
import org.springframework.web.reactive.function.server.ServerResponse;

import tech.commit.sigdep.gatewayproxy.handlers.user.UserReadHandler;
import tech.commit.sigdep.gatewayproxy.utils.CommonUtils.Path;

@Configuration
public class UserRouter {

    private final UserReadHandler handler;

    public UserRouter(UserReadHandler handler) {
        this.handler = handler;
    }

    /**
     * This method defines the routes for user-related operations.
     * It uses Spring WebFlux's RouterFunction to create a functional routing configuration.
     *
     * @return RouterFunction<ServerResponse> - The routing function for user operations.
     */
    
    @Bean(name = "userRoutes")
    public RouterFunction<ServerResponse> userRoutes() {
        
        return route()
                .GET(Path.ID, handler::getUserById)
                .build();
    }
}
