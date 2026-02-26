# Implementation Plan: MQTT MTP Implementation

**Branch**: `003-implement-mqtt-mtp` | **Date**: 2025-11-25 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/003-implement-mqtt-mtp/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

This plan outlines the implementation of an MQTT Message Transfer Protocol (MTP) service for the USP Device:2 Simulator. The core objective is to enable the simulator to connect to an external MQTT broker, subscribe to an agent-specific topic, process incoming USP requests, and publish responses. This will allow the simulator to be tested in standard IoT network topologies. The implementation will be encapsulated in a new `MqttMtpService` class within the infrastructure layer, leveraging the existing `UspMessageAdapter` for request processing.

## Technical Context

**Language/Version**: Dart (SDK >= 3.0)
**Primary Dependencies**: `mqtt_client` (v10.x), `usp_protocol_common`, `riverpod` (v2.x)
**Storage**: N/A (State is managed in-memory by the `DeviceTree`)
**Testing**: `test` (Dart's standard unit testing framework)
**Target Platform**: Headless Server (Dart VM)
**Project Type**: Monorepo (`apps/usp_device2_simulator`)
**Performance Goals**: Process a `Get` request and publish the `GetResp` within 2 seconds.
**Constraints**: Must handle connection failures gracefully with a defined retry strategy. Logging must adhere to the project's standardized format.
**Scale/Scope**: The initial implementation will support a single, persistent MQTT client connection to one broker.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Justification |
| :--- | :--- | :--- |
| **Domain First** | ✅ PASS | The `MqttMtpService` will be implemented in the `infrastructure/transport` layer and will interact with the domain via the `UspMessageAdapter`, respecting the Clean Architecture boundaries. |
| **Immutable State** | ✅ PASS | This feature does not directly modify the `DeviceTree`. It relies on the existing application use cases which are responsible for ensuring copy-on-write principles are met. |
| **Fail Fast** | ✅ PASS | The implementation will handle invalid USP messages and connection errors as specified, throwing exceptions or logging errors as appropriate. |
| **Contract over Implementation** | ✅ PASS | All USP message handling will use the DTOs and converters defined in the `usp_protocol_common` shared kernel, adhering to the established contract. |
| **Config-Driven Testing**| ✅ PASS | The specification requires a `verify_server_mqtt.dart` script, which aligns with the principle of creating dedicated, configuration-driven verification tools. |

**Result**: All constitution gates pass. No violations to report.

## Project Structure

### Documentation (this feature)

```text
specs/003-implement-mqtt-mtp/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output (Not applicable for this feature)
└── tasks.md             # Phase 2 output (created by /speckit.tasks)
```

### Source Code (repository root)

The implementation will follow the existing project structure. A new service will be added to the infrastructure layer.

```text
lib/
└── infrastructure/
    └── transport/
        ├── mqtt_mtp_service.dart     # New MQTT MTP implementation
        └── websocket_mtp_server.dart # Existing WebSocket MTP
bin/
├── server.dart                 # Will be updated to launch MqttMtpService
└── verify_server_mqtt.dart     # New verification script for MQTT
```

**Structure Decision**: The selected structure adheres to the established Clean Architecture and monorepo layout. New transport-specific code is correctly placed in `lib/infrastructure/transport`, and a new verification script will be added to `bin` for easy execution.

## Complexity Tracking
> No violations to report.