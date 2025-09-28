# Trinity

Trinity is a monorepo for a full-stack e-commerce application. It includes a backend API, a web frontend, and a mobile application.

## Tech Stack

*   **Backend**: Go (with Echo framework) and MongoDB
*   **Frontend**: SvelteKit
*   **Mobile**: Flutter
*   **Containerization**: Docker

## Project Structure

The monorepo is organized as follows:

*   `backend/`: The Go backend API.
*   `frontend/`: The SvelteKit web application.
*   `mobile/`: The Flutter mobile application.
*   `docker-compose.yml`: Docker configuration for the development environment.
*   `docker-compose_prod.yml`: Docker configuration for the production environment.
*   `gitlab/`: GitLab CI/CD configuration files.

## Getting Started

### Prerequisites

*   Docker and Docker Compose
*   Go (for backend development without Docker)
*   Node.js (for frontend development without Docker)
*   Flutter SDK (for mobile development)

### Configuration

1.  Copy the example environment file:
    ```bash
    cp .env.exemple .env
    ```
2.  Update the `.env` file with your configuration.

### Running the application

#### Development

To run the entire application stack in a development environment, use the following command:

```bash
./dev.sh
```

This will start the backend, frontend, and database using `docker-compose`.

#### Production

To run the application in a production environment, use:

```bash
./prod.sh
```

This command uses `docker-compose_prod.yml` to build and run the production containers.

## Available Scripts

*   `dev.sh`: Starts the development environment.
*   `prod.sh`: Starts the production environment.
*   `seed.sh`: Seeds the database with initial data. This script is intended to be run in a production-like environment and might require `sudo`.

## API

The backend API is documented using Bruno. You can find the API collection in the `backend/bruno_api/` directory.