# USP Device Simulator

[](ARCHITECTURE.md)
[](https://usp.technology/)
[](https://melos.invertase.dev/)

A **USP (User Services Platform / TR-369)** compliant device simulator with multi-transport support (gRPC, WebSocket, HTTP, MQTT).

## Workspace Structure

| Type | Path | Description |
| :--- | :--- | :--- |
| **Shared Kernel** | `packages/usp_protocol_common` | Pure Dart definitions for Protobuf, DTOs, and Transport Interfaces. |
| **Simulator** | `apps/usp_device2_simulator` | Headless USP Agent simulator compliant with TR-181, with built-in Gateway Proxy. |
| **Infra** | `infrastructure/` | Docker configurations for **Mosquitto** (MQTT Broker). |

-----

## High-Level Architecture

The simulator exposes multiple transport endpoints for USP clients to connect.

```text
    [ External USP Client ]
     (gRPC / WebSocket / HTTP / MQTT)
              |
              v
    +-------------------------+          +------------------+
    | USP Device Simulator    | <------> | Mosquitto Broker |
    | gRPC:  50051            |  MQTT    |  (Docker: 1883)  |
    | WS:    8080             |          +------------------+
    | HTTP:  8081             |
    +-------------------------+
```

For detailed architectural decisions, see [**ARCHITECTURE.md**](ARCHITECTURE.md).

-----

## Prerequisites

  - **Dart SDK**: Latest Stable (>= 3.8.0)
  - **Docker**: Required for running the infrastructure stack (Mosquitto).
  - **Protoc**: Protocol Buffer Compiler (for regenerating code).
  - **Melos**: Monorepo management tool.

## Getting Started

### 1. Install Melos

```bash
dart pub global activate melos
```

### 2. Bootstrap Workspace

Links all local packages and installs dependencies.

```bash
melos bootstrap
```

### 3. Generate Protobuf Contracts

Ensure all DTOs and gRPC stubs are up-to-date.

```bash
melos run proto:gen
```

-----

## Development Workflow

### Step 1: Start Infrastructure (Docker)

This command builds and starts the **Mosquitto Broker** in the background.

```bash
melos run infra:start
```

### Step 2: Run Simulator

This starts the Dart Simulator locally, connecting it to the Docker Broker.

```bash
melos run sim:run
```

  * **gRPC Gateway**: `0.0.0.0:50051`
  * **WebSocket**: `0.0.0.0:8080`
  * **HTTP MTP**: `0.0.0.0:8081`
  * **MQTT**: Connected to `localhost:1883`

-----

## Melos Scripts Reference

Use `melos run <script>` to execute these commands.

### Infrastructure Management (Docker)

| Command | Description |
| :--- | :--- |
| `infra:start` | Start Simulator and Mosquitto in background. |
| `infra:stop` | Stop and remove all infrastructure containers. |
| `infra:restart`| Restart all containers. |
| `infra:logs` | Tail logs for all containers. |
| `infra:logs:tail` | Follow logs stream. |

### Simulator (Local Debugging)

| Command | Description |
| :--- | :--- |
| `sim:run` | Run Simulator locally with default settings. |

### Verification & Testing

| Command | Description |
| :--- | :--- |
| `verify:grpc` | Run gRPC Client script to verify Client -> Gateway -> Agent flow. |
| `verify:mqtt` | Run MQTT Client script to verify Pub/Sub lifecycle. |
| `verify:ws` | Run WebSocket script to verify basic connectivity. |
| `test:all` | Run unit/widget tests across all packages. |

### Development Tools

| Command | Description |
| :--- | :--- |
| `proto:gen` | Regenerate Protobuf Dart code in `common` package using `protoc`. |

-----

## Project Directory Map

```text
/ (Root)
├── melos.yaml                # Monorepo script definitions
├── infrastructure/           # Docker & Network configs
│   ├── docker-compose.yaml   # Orchestrates Simulator and Broker
│   └── mosquitto/config/     # MQTT Broker Config
├── packages/
│   └── usp_protocol_common/  # [Shared Kernel] DTOs, Proto files, Converters
└── apps/
    └── usp_device2_simulator/# USP Agent & Gateway logic
        ├── bin/server.dart   # Entry point
        └── Dockerfile        # Optimized Docker build
```

-----

## Troubleshooting Guide

### 1. MQTT "Connection Refused" (errno = 111 or 61)

  * **Symptom**: Simulator logs show `SocketException: Connection refused` repeating.
  * **Cause**: The MQTT Broker container is not running, or `mosquitto.conf` is missing.
  * **Fix**:
    1.  Ensure the `infrastructure/mosquitto/config/mosquitto.conf` file exists.
    2.  Run `melos run infra:start` to restart containers.
    3.  Check logs: `docker logs usp-broker`.

### 2. "Bad State" or "Null Check Operator" in Tests

  * **Symptom**: Tests fail with cryptic errors.
  * **Cause**: Usually due to missing **Mock Fallbacks** or **Stubbing** in `mocktail`.
  * **Fix**: Ensure your test's `setUpAll` registers necessary fallbacks (e.g., `registerFallbackValue(FakeStackTrace())`).

### 3. "Target of URI hasn't been generated"

  * **Symptom**: IDE shows red errors on `import ...pb.dart`.
  * **Cause**: Protobuf files are not generated or are outdated.
  * **Fix**: Run `melos run proto:gen` to regenerate all contracts.
