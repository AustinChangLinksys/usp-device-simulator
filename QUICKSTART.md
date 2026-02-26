# Quick Start Guide

This guide will help you get the USP Device Simulator running quickly.

## Prerequisites

*   **Docker Desktop**: Ensure Docker is installed and running.

## Start Infrastructure (Simulator + Broker)

### Option 1: Using Melos (Recommended for Developers)

If you have the repository and `melos` installed:

```bash
# 1. Start infrastructure
melos run infra:start

# 2. Stop infrastructure
melos run infra:stop
```

### Option 2: Direct Shell Commands (No Melos)

```bash
# Start
docker compose -f infrastructure/docker-compose.yaml up --build -d

# Stop
docker compose -f infrastructure/docker-compose.yaml down

# View Logs
docker compose -f infrastructure/docker-compose.yaml logs -f
```

## Available Endpoints

Once the infrastructure is running, the simulator exposes:

| Protocol | Port | Description |
| :--- | :--- | :--- |
| **gRPC** | `50051` | gRPC Gateway |
| **WebSocket** | `8080` | WebSocket MTP |
| **HTTP** | `8081` | HTTP MTP |
| **MQTT** | `1883` | Via Mosquitto Broker |

## Troubleshooting

**"Connection Refused" or "Network Error"**
*   Ensure all containers are running: `docker ps`
    *   You should see: `usp-broker` and `infrastructure-simulator-1`.
