
![SigDep](./docs/images/sigdep-logo.png)

# SigDep

Event-Driven Task and Event Management System (ED-TEMS)

[![GPL 3.0 License](https://img.shields.io/badge/license-GPL_v3.0-blue.svg)](https://www.gnu.org/licenses/gpl-3.0) ![Static Badge](https://img.shields.io/badge/build%20-%20passing%20-%20green) ![Static Badge](https://img.shields.io/badge/release%20-%20v0.1%20-%20orange)


## Overview

SigDep (codename: ED-TEMS) is a distributed, scalable architecture designed to manage user-defined tasks and events. Built on microservices and event-driven communication patterns, the system supports complex task structures (including sub-task structure, attachments) with dynamic workflows like status and priority update and seamless synchronization with external calendaring services such as Google Calendar.


##  Architecture

The system consists of loosely coupled microservices that interact via HTTP (REST) and, optionally, an event-driven message broker (Kafka). The API Gateway serves as a single entry point for all client requests with a WebUI which helps facilitate user actions.


## Features

[Development Kanban board](https://traveling-quilt-2f7.notion.site/SigDep-1cdd7ad4001780cb9f74f7bc3f611564)

_Top-Level Features_

- **Scalable Microservices Architecture (CP-focused)**
  - Built using a modular microservices design emphasizing Consistency and Partition Tolerance (CP) as per the CAP theorem.
  - Ensures high availability through eventual consistency using an event-driven architecture with message queues (e.g., Kafka, RabbitMQ).
  - Supports horizontal scalability and independent deployment of services for robust performance under load.

- **Comprehensive Task and Event Lifecycle Management**
  - Create, update, delete, and replicate tasks or events across workspaces.
  - Support for recurring events with flexible repeat intervals and termination conditions.
  - Rich metadata support including tags, priorities, deadlines, and status tracking.

- **Secure User Authentication and Role-Based Access Control**
  - Integrated with identity providers (e.g., Auth0, OAuth2) for secure user login and token-based access.
  - Role-based access control (RBAC) enabling granular permissions at workspace and resource levels (coming soon!).
  - Multi-tenant support for collaborative environments.

- **Event Reminders and Real-Time Notifications**
  - Push notifications delivered via WebSockets or push services (e.g., Firebase Cloud Messaging) for task/event alerts and updates.
  - Customizable reminder settings for users at task/event level.
  - Notification center for tracking all alerts and history.

- Centralized API Access via API Gateway
  - Unified API gateway handling authentication, validation, and routing to internal services.
  - Built-in request throttling, rate-limiting, and monitoring capabilities.
  - Enables API versioning and seamless external access management.

- **Google Calendar Integration for 3rd Party Sync**
  - Two-way synchronization with Google Calendar, allowing users to view and manage SigDep events through third-party calendar clients.
  - Events created in SigDep are mirrored in Google Calendar, maintaining metadata and reminders.
  - Supports automatic sync and conflict resolution between systems.


## Roadmap

- Additional browser support

- Add more integrations


## Services

Tablular description of services


## Tech Stack

**Client:** React, Redux, TailwindCSS

**Server:** Node, Express


## Installation

Install my-project with npm

```bash
  npm install my-project
  cd my-project
```
    
## Usage/Examples

Access the API Gateway: http://localhost:8000

Use Swagger docs: http://localhost:<SERVICE_PORT>/docs


## API Reference

#### Get all items

```http
  GET /api/items
```

| Parameter | Type     | Description                |
| :-------- | :------- | :------------------------- |
| `api_key` | `string` | **Required**. Your API key |

#### Get item

```http
  GET /api/items/${id}
```

| Parameter | Type     | Description                       |
| :-------- | :------- | :-------------------------------- |
| `id`      | `string` | **Required**. Id of item to fetch |

#### add(num1, num2)

Takes two numbers and returns the sum.


## Run Locally

Clone the project

```bash
  git clone git@github.com:abhishek-raut17/sigdep.git
```

Go to the project directory

```bash
  cd my-project
```

Install dependencies

```bash
  npm install
```

Start the server

```bash
  npm run start
```


## Screenshots

![App Screenshot](https://via.placeholder.com/468x300?text=App+Screenshot+Here)


## Authors

- [Abhishek Raut](https://github.com/abhishek-raut17)


## License

[AGPL](https://choosealicense.com/licenses/agpl/)



## References and Links

[Feature Kanban board](https://traveling-quilt-2f7.notion.site/SigDep-1cdd7ad4001780cb9f74f7bc3f611564)