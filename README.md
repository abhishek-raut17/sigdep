
![SigDep](./docs/images/sigdep-logo.png)

# SigDep

Event-Driven Task and Event Management System (ED-TEMS)

[![GPL 3.0 License](https://img.shields.io/badge/license-GPL_v3.0-blue.svg)](https://www.gnu.org/licenses/gpl-3.0) ![Static Badge](https://img.shields.io/badge/build%20-%20passing%20-%20green) ![Static Badge](https://img.shields.io/badge/version%20-%20v0.1%20-%20orange)


## Overview

SigDep (codename: ED-TEMS) is a distributed, scalable architecture designed to manage user-defined tasks and events. Built on microservices and event-driven communication patterns, the system supports complex task structures (including sub-task structure, attachments) with dynamic workflows like status and priority update and seamless synchronization with external calendaring services such as Google Calendar.


##  Architecture

The system consists of loosely coupled microservices that interact via HTTP (REST) and, optionally, an event-driven message broker (Kafka). The API Gateway serves as a single entry point for all client requests with a WebUI which helps facilitate user actions.


## Features

[Development Kanban board](https://traveling-quilt-2f7.notion.site/SigDep-1cdd7ad4001780cb9f74f7bc3f611564)

- Scalable microservice-based design focusing on consistency and availability (CA)
- Task and event lifecycle management
- User authentication and role-based access
- Event reminders and real-time notifications
- Centralized API access through a gateway
- Synchronization with Google Calendar for 3rd party clients to access via Google Calendar


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