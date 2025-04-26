# Tech Stack

SigDep is built with a modern, cloud-native technology stack optimized for distributed systems, event-driven architectures, and developer productivity.

---

## Backend Microservices

All backend domain services (e.g., Task Service, Event Service, Notification Service) are implemented using:

- **Framework:** [Spring Boot](https://spring.io/projects/spring-boot) (Java 21+)
- **Communication (Internal):** [gRPC](https://grpc.io/) for fast, typed, binary inter-service calls
- **Communication (Async):** [Apache Kafka](https://kafka.apache.org/) for pub/sub and event-driven workflows
- **API Documentation:** [SpringDoc + OpenAPI 3](https://springdoc.org/)

---

## Data Persistence

SigDep uses a **CQRS + Event Sourcing** pattern, separating write and read concerns across different persistence layers.

### Write Side (Command Services)

- **Database:** [EventStoreDB](https://eventstore.com/)
  - Used as an **append-only, immutable event store**
  - Enables full audit trail and state reconstruction via event replay

### Read Side (Query Services)

- **Read Databases:**
  - [PostgreSQL](https://www.postgresql.org/): for structured relational queries
  - [MongoDB](https://www.mongodb.com/): for flexible, denormalized views
  - [Redis](https://redis.io/): for low-latency caching and materialized views
- Read models are updated reactively via Kafka event subscribers

---

## API Gateway

- **Technology:** [gRPC Gateway](https://grpc-ecosystem.github.io/grpc-gateway/) (or custom Kotlin/Java-based REST gateway)
- **Responsibilities:**
  - Auth handling and RBAC enforcement
  - Routing to gRPC-based command services
  - Rate limiting, logging, and tracing (OpenTelemetry)

---

## Frontend

- **Framework:** [React.js](https://reactjs.org/)
- **State Management:** [Redux](https://redux.js.org/)
- **UI Toolkit:** [TailwindCSS](https://tailwindcss.com/)
- **API Integration:** REST over Axios/Fetch to API Gateway

---

## Notifications

- **Push Service:** [Firebase Cloud Messaging (FCM)](https://firebase.google.com/docs/cloud-messaging)
- **Delivery Logic:** Event-driven microservice listening to Kafka topics for time-based and action-based triggers

---

## Authentication & Security

- **Auth Provider:** [Auth0](https://auth0.com/) or any OAuth2-compliant identity provider
- **Session Strategy:** JWT + access/refresh token pattern
- **Upcoming:** Role-Based Access Control (RBAC), Multi-Tenant Isolation

---

## Tooling & Observability

- **API Docs:** Swagger / OpenAPI 3 via SpringDoc
- **Monitoring & Logs:** Prometheus + Grafana, ELK stack (ElasticSearch, Logstash, Kibana)
- **Tracing:** OpenTelemetry / Jaeger
- **CI/CD:** GitHub Actions, Docker, Kubernetes (Helm Charts)

---

## 3rd Party Integrations

- **Calendar Sync:** [Google Calendar API](https://developers.google.com/calendar)
- **OAuth2 Providers:** Google, GitHub, etc.

---

## Dev Experience

- **Local Dev:** Docker Compose stack with Kafka, EventStoreDB, Postgres, Mongo
- **Testing:** JUnit, Mockito, TestContainers, Pact (for contract testing)
- **Code Quality:** SonarQube, Checkstyle, ESLint (frontend)

---

> ⚡ Built to scale, tested for reliability, and architected for evolution.
