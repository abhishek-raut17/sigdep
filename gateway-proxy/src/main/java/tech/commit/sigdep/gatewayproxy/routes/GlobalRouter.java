package tech.commit.sigdep.gatewayproxy.routes;

import static org.springframework.web.reactive.function.server.RouterFunctions.route;
import static org.springframework.web.reactive.function.server.RouterFunctions.nest;
import static org.springframework.web.reactive.function.server.RequestPredicates.path;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.reactive.function.server.RouterFunction;
import org.springframework.web.reactive.function.server.ServerResponse;

import tech.commit.sigdep.gatewayproxy.utils.CommonUtils.URI;

@Configuration
public class GlobalRouter {
    
    @Bean(name = "globalRoutes")
    public RouterFunction<ServerResponse> globalRoutes(final UserRouter userRouter, final TaskRouter taskRouter) {

        return nest(path(URI.BASE),
                route()
                    .add(nest(path(URI.USER), userRouter.userRoutes()))
                    .add(nest(path(URI.TASK), taskRouter.taskRoutes()))
                    .build()
        );
    }
}
