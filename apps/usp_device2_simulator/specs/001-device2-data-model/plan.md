# Implementation Plan: TR-181 Device:2 Data Model Engine - JSON Configuration Loading (FR-016)

**Branch**: `001-device2-data-model` | **Date**: 2025-11-21 | **Spec**: `specs/001-device2-data-model/spec.md`
**Input**: Feature specification from `/specs/001-device2-data-model/spec.md`



## Summary

This project aims to develop a high-performance, high-fidelity TR-181 Device:2 data model engine (i.e., "high-fidelity" simulation) as a core component for a USP Agent. This engine will handle complex data structures, path resolution, parameter validation, and state lifecycle management. It supports data model construction via XML Schema and parameter overriding via JSON configuration. Technically, it adopts Clean Architecture, Domain-Driven Design (DDD), and Design-by-Contract (DBC) principles to achieve automated and flexible model configuration.

## Technical Context

**Language/Version**: Dart (SDK >= 3.0)
**Primary Dependencies**: usp_protocol_common, json_serializable, xml, dart:convert (for JSON parsing)
**Storage**: Files (for configuration and state persistence)
**Testing**: Dart unit tests, high coverage in Domain Layer
**Target Platform**: Headless Service
**Project Type**: Single project (library/service)
**Performance Goals**: Loading the complete tr-181-2-16-0.xml model and starting the service must complete within 2 seconds; JSON configuration loading should complete within 500 ms and not significantly impact startup time.
**Constraints**: Ensure data model consistency through DBC; strictly enforce Copy-on-Write pattern to maintain state immutability; error handling complies with USP Protocol Error standards; JsonConfigLoader must ignore parameter writable attributes but still perform type validation.
**Scale/Scope**: Automated capability to generate or instantiate thousands of data nodes from Schema; JSON configuration should handle typical configuration file sizes.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

The data model engine implemented in this project is highly consistent with the core principles of the constitution. The added `JsonConfigLoader` functionality also conforms to the following principles:

*   **Project Vision & Mission**: Directly corresponds to the vision in the constitution of "building a highly simulated, well-architected, and Broadband Forum TR-369/TR-181 standard-compliant USP Agent data model core," realizing its mission through Clean Architecture, DDD, and DBC. `JsonConfigLoader` enhances configuration flexibility.
*   **Project Objectives**: The project objectives of "standard compliance," "architectural purity," "robustness," and "automation capabilities" will be fully achieved in this project, especially in terms of TR-181 data model structure support, Clean Architecture layering, DBC robustness, and Schema-driven automation. `JsonConfigLoader` ensures robustness through type validation and strengthens configuration automation.
*   **Architectural Principles & Guidelines**: 
    *   **Domain First**: `JsonConfigLoader`, as a component of the Infrastructure layer, interacts with the Domain via `DeviceRepository`, adhering to this principle.
    *   **Immutable State**: Parameter values are updated via the `updateInternally` mechanism, maintaining the principle of `DeviceTree` immutability.
    *   **Fail Fast**: JSON parsing errors or type validation failures will immediately throw exceptions, adhering to the Fail Fast principle.
    *   **Test Driven**: `JsonConfigLoader` itself will also follow Test-Driven Development principles.

Conclusion: This feature plan, including the addition of `JsonConfigLoader`, fully complies with the project constitution and has no conflicts.

## Project Structure

### Documentation (this feature)

```text
specs/001-device2-data-model/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
lib/
├── domain/              # Core business rules, entities, value objects, interfaces
│   ├── entities/        # Aggregate Roots and Entities
│   ├── value_objects/   # Immutable Value Objects (from usp_protocol_common)
│   └── repositories/    # Abstract repository interfaces
├── application/         # Application-specific logic, orchestrates domain
│   ├── usecases/        # Application-specific use cases
│   └── services/        # Application services for orchestration
└── infrastructure/      # External integrations, data sources, state management
    ├── persistence/     # Data persistence implementations (e.g., JsonPersistenceService)
    ├── schema/          # Schema loading and parsing implementations (e.g., XmlSchemaLoader)
    ├── config/          # Configuration loading implementations (e.g., JsonConfigLoader)
    ├── state/           # State management implementations (e.g., Riverpod Notifiers) - Riverpod no longer in use
    ├── provisioning/    # Smart Provisioning logic (e.g., SmartProvisioner)
    └── transport/       # Transport Layer (e.g. WebSocketMtpServer)

test/
├── domain/
├── application/
└── infrastructure/
    ├── persistence/
    ├── schema/
    ├── config/          # Tests for JsonConfigLoader
    ├── provisioning/    # Tests for SmartProvisioner
    └── transport/       # Tests for WebSocketMtpServer
```

**Structure Decision**: A single project structure was chosen, employing strict Clean Architecture layering. The Domain Layer is subdivided into `entities` and `value_objects`, and Use Cases are clearly placed within the Application Layer. A new `config/` directory was added under `infrastructure/` to house `JsonConfigLoader`, with corresponding test directories added under `test/infrastructure/`, ensuring the purity of domain logic and compliance with the project's constitutional principle of "architectural purity". Added `provisioning/` and `transport/` directories under `infrastructure/` and corresponding test directories.


