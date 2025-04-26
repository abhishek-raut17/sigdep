# Architecture

SigDep leverages a distributed microservices architecture to achieve scalability, availability, and maintainability. Its design incorporates event-driven communication, CQRS (Command Query Responsibility Segregation), and event sourcing, ensuring responsive, consistent, and auditable operations.

## Key Features

### Microservices-First Design

- Each domain (e.g., Tasks, Events, Notifications, Users) is encapsulated within its own service boundary.
- Adheres to the Single Responsibility Principle, enabling independent deployment, scaling, and ownership.

### Event-Driven Core

- Services communicate asynchronously via a message broker (e.g., Kafka, RabbitMQ).
- Ensures loose coupling, reactive pipelines, and non-blocking communication.

### CQRS and Event Sourcing

- **Command Services** handle write operations and persist changes as immutable event streams.
- **Query Services** maintain optimized read models, updated in real-time by event subscribers.
- Employs polyglot persistence: PostgreSQL for writes, Redis or Elasticsearch for reads.
- Supports high-throughput writes, scalable reads, and complete audit logs.

## Communication Layers

### Internal Communication

- **gRPC** is used for service-to-service communication, offering low-latency, language-agnostic, and strongly typed RPC mechanisms.
- Ideal for real-time workflows like reminders and calendar synchronization.

### External Access

- **API Gateway** serves as the ingress layer for external RESTful traffic:
  - **Authentication & RBAC**: Token-based authentication (OAuth2, JWT) with planned Role-Based Access Control.
  - **Routing & Aggregation**: Smart routing to Command or Query services based on HTTP methods or route patterns.
  - **Rate Limiting & Observability**: Built-in rate limiting, logging, and tracing, compatible with OpenTelemetry and Prometheus.

## System Flow Overview

1. **Client Request**  
           A client sends a request to the API Gateway (e.g., `POST /api/task`). The Gateway routes it to the appropriate Command Service (e.g., `TaskService.Write`) via REST or gRPC.

2. **Command Service**  
           Validates input, emits domain events, and persists them in an append-only event store (e.g., PostgreSQL, EventStoreDB).

3. **Event Consumers**  
           Listen to the event stream and update read models (e.g., Redis, MongoDB) within Query Services.

4. **Query Services**  
           Provide fast, denormalized data for frontend UIs and external clients via RESTful endpoints or GraphQL.

5. **Real-Time Notifications**  
           Notification services react to events and push updates to clients via WebSockets or push services like Firebase.
