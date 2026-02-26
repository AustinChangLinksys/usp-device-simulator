# Implementation Tasks: TR-181 Device:2 Data Model Engine

**Feature Branch**: 001-device2-data-model | **Date**: 2025-11-21
**Spec**: specs/001-device2-data-model/spec.md
**Plan**: specs/001-device2-data-model/plan.md

## Summary

This task list guides the development of the TR-181 Device:2 Data Model Engine. Tasks are grouped by functional priority and dependencies to support independent development and testing. The project will adopt Clean Architecture and strictly adhere to Domain-Driven Design (DDD) and Design-by-Contract (DBC) principles.

## Phases

### Phase 1: Setup - Project Initialization and Core Structure

**Goal**: Establish the foundational project structure and initial dependencies.

- [x] T001 Create core directory structure: `lib/domain/`, `lib/application/`, `lib/infrastructure/`, `test/`
- [x] T002 Configure `pubspec.yaml` with initial dependencies: `xml`, `json_serializable`, `build_runner` (dev)
- [x] T003 Set up `analysis_options.yaml` for Dart linting and static analysis
- [x] T004 Create initial `lib/usp_device2_simulator.dart` placeholder file

### Phase 2: Foundational - Core Domain & Interfaces

**Goal**: Define the fundamental building blocks of the domain model and essential interfaces, blocking for all user stories.

- [x] T005 Use `UspException` class from `usp_protocol_common`
- [x] T006 Use `UspValueType` enum from `usp_protocol_common`
- [x] T007 Use `UspValue` value object from `usp_protocol_common`
- [x] T008 Use `InstanceId` value object from `usp_protocol_common`
- [x] T009 Use `UspPath` value object from `usp_protocol_common`
- [x] T010 Define abstract `UspNode` entity in `lib/domain/entities/usp_node.dart`
- [x] T011 Define `UspObject` entity (extends `UspNode`) in `lib/domain/entities/usp_object.dart`
- [x] T012 Define `UspParameter` entity (extends `UspNode`) in `lib/domain/entities/usp_parameter.dart`
- [x] T013 Define `UspCommand` entity (extends `UspNode`) in `lib/domain/entities/usp_command.dart`
- [x] T014 Define `DeviceTree` aggregate root in `lib/domain/entities/device_tree.dart`
- [x] T015 Define `IDeviceRepository` interface in `lib/domain/repositories/i_device_repository.dart`
- [x] T016 Define `ISchemaLoader` interface in `lib/infrastructure/schema/i_schema_loader.dart`
- [x] T017 Define `IPersistenceService` interface in `lib/infrastructure/persistence/i_persistence_service.dart`

### Phase 3: User Story 1 - Data Access (Get/Set) (P1)

**Goal**: Implement basic Get/Set operations for parameters, ensuring core data access.

**Independent Test**: Simulate calls to `GetParameterValueUseCase` and `SetParameterValueUseCase` with hardcoded `DeviceTree` data, verifying returned values and error codes.

- [x] T018 [US1] Implement `GetParameterValueUseCase` in `lib/application/usecases/get_parameter_value_usecase.dart`
- [x] T019 [US1] Implement `SetParameterValueUseCase` in `lib/application/usecases/set_parameter_value_usecase.dart`
- [x] T020 [US1] Create `DeviceRepositoryImpl` (initial stub for Get/Set) in `lib/infrastructure/repositories/device_repository_impl.dart`
- [x] T021 [US1] Implement unit tests for `GetParameterValueUseCase` in `test/application/usecases/get_parameter_value_usecase_test.dart`
- [x] T022 [US1] Implement unit tests for `SetParameterValueUseCase` in `test/application/usecases/set_parameter_value_usecase_test.dart`
- [x] T023 [US1] Implement unit tests for `DeviceRepositoryImpl` (stub) in `test/infrastructure/repositories/device_repository_impl_test.dart`

### Phase 4: User Story 2 - Path Resolution (P1)

**Goal**: Enhance path handling to support wildcards and alias filtering for flexible data access.

**Independent Test**: Provide `UspPath` objects with various wildcard/alias patterns and verify the system correctly resolves and returns target nodes/values.

- [x] T024 [P] [US2] Utilize `UspPath` from `usp_protocol_common` for wildcard (`*`) support
- [x] T025 [P] [US2] Utilize `UspPath` from `usp_protocol_common` for alias filtering (`[Alias=="Guest"]`)
- [x] T026 [US2] Utilize `PathResolver` service from `usp_protocol_common`
- [x] T027 [US2] Update `DeviceRepositoryImpl` to utilize enhanced path resolution in `lib/infrastructure/repositories/device_repository_impl.dart`
- [x] T028 [US2] Implement unit tests for `UspPath` wildcard support in `test/domain/value_objects/usp_path_wildcard_test.dart`
- [x] T029 [US2] Implement unit tests for `UspPath` alias filtering in `test/domain/value_objects/usp_path_alias_test.dart`
- [x] T030 [US2] Implement unit tests for path resolution logic in `test/domain/services/path_resolver_test.dart`

### Phase 5: User Story 5 - Schema Driven (P1)

**Goal**: Enable dynamic construction of the data model from a TR-181 XML Schema, removing hardcoded structures.

**Independent Test**: Load a valid TR-181 XML Schema file and verify the `DeviceTree` is correctly built in memory, including all objects, parameters, and commands. Test with invalid schema for error handling.

- [x] T031 [US5] Implement `XmlSchemaLoader` (implements `ISchemaLoader`) in `lib/infrastructure/schema/xml_schema_loader.dart`
- [x] T032 [US5] Implement logic within `XmlSchemaLoader` to parse TR-181 XML into `DeviceTree` entities
- [x] T033 [US5] Integrate `XmlSchemaLoader` into the application's initialization flow (e.g., in `main.dart` or an application service)
- [x] T034 [US5] Implement unit tests for `XmlSchemaLoader` with valid XML in `test/infrastructure/schema/xml_schema_loader_test.dart`
- [x] T035 [US5] Implement unit tests for `XmlSchemaLoader` with invalid XML (error handling) in `test/infrastructure/schema/xml_schema_loader_error_test.dart`

### Phase 6: User Story 3 - Dynamic Lifecycle Management (P2)

**Goal**: Implement functionality to dynamically add and delete multi-instance objects.

**Independent Test**: Simulate `AddObjectUseCase` and `DeleteObjectUseCase` calls, verifying correct object creation/deletion, Instance ID allocation, and associated error handling.

- [x] T036 [US3] Implement `AddObjectUseCase` in `lib/application/usecases/add_object_usecase.dart`
- [x] T037 [US3] Implement `DeleteObjectUseCase` in `lib/application/usecases/delete_object_usecase.dart`
- [x] T038 [US3] Update `DeviceTree` to support `addObject` and `deleteObject` logic
- [x] T039 [US3] Update `DeviceRepositoryImpl` to expose `addObject` and `deleteObject` operations
- [x] T040 [US3] Implement unit tests for `AddObjectUseCase` in `test/application/usecases/add_object_usecase_test.dart`
- [x] T041 [US3] Implement unit tests for `DeleteObjectUseCase` in `test/application/usecases/delete_object_usecase_test.dart`

### Phase 7: User Story 4 - State Notifications (P2)

**Goal**: Establish a notification system for parameter value changes and object lifecycle events.

**Independent Test**: Subscribe to notification events and verify that `ValueChangeNotification`, `ObjectCreationNotification`, and `ObjectDeletionNotification` are correctly emitted upon relevant operations, with accurate content.

- [x] T042 [US4] Define `Notification` base class and specific notification types (e.g., `ValueChangeNotification`, `ObjectCreationNotification`, `ObjectDeletionNotification`) in `lib/domain/events/notifications.dart`
- [x] T043 [US4] Implement notification publishing mechanism within `DeviceTree`
- [x] T044 [US4] Integrate `ValueChangeNotification` into `SetParameterValueUseCase` and `DeviceTree`
- [x] T045 [US4] Integrate `ObjectCreationNotification` into `AddObjectUseCase` and `DeviceTree`
- [x] T046 [US4] Integrate `ObjectDeletionNotification` into `DeleteObjectUseCase` and `DeviceTree`
- [x] T047 [US4] Implement unit tests for `ValueChangeNotification` in `test/domain/events/value_change_notification_test.dart`
- [x] T048 [US4] Implement unit tests for `ObjectCreationNotification` in `test/domain/events/object_creation_notification_test.dart`
- [x] T049 [US4] Implement unit tests for `ObjectDeletionNotification` in `test/domain/events/object_deletion_notification_test.dart`

### Phase 8: User Story 6 - JSON Configuration Loading (FR-016) (P1)

**Goal**: Implement `JsonConfigLoader` to load configuration from JSON files and override default values.

**Independent Test**: Load XML schema, then load JSON config, verify overridden parameter values for a selection of parameters.

- [x] T050 [US6] Define `IConfigLoader` interface in `lib/infrastructure/config/i_config_loader.dart`
- [x] T051 [US6] Implement `JsonConfigLoader` (implements `IConfigLoader`) in `lib/infrastructure/config/json_config_loader.dart`
- [x] T052 [US6] Implement logic within `JsonConfigLoader` to parse JSON and apply values using `updateInternally`
- [x] T053 [US6] Integrate `JsonConfigLoader` into `DeviceRepositoryImpl` initialization flow
- [x] T054 [US6] Implement unit tests for `JsonConfigLoader` with valid JSON in `test/infrastructure/config/json_config_loader_test.dart`
- [x] T055 [US6] Implement unit tests for `JsonConfigLoader` with invalid JSON (error handling) in `test/infrastructure/config/json_config_loader_error_test.dart`

### Final Phase: Polish & Cross-Cutting Concerns

**Goal**: Ensure the system meets non-functional requirements, covers edge cases, and is robust for production use.

- [x] T056 Implement `PersistenceService` (e.g., JSON-based) in `lib/infrastructure/persistence/json_persistence_service.dart`
- [x] T057 Integrate persistence into application initialization and shutdown (load/save `DeviceTree` state)
- [x] T058 Review and refine error handling across all layers, ensuring consistent `UspException` usage
- [x] T059 Conduct comprehensive Domain Layer test coverage audit, achieved 91.5%.
- [x] T060 Perform performance testing to ensure TR-181 XML loading completes within 2 seconds
- [x] T061 Document overall system architecture and API usage in `README.md`

## Dependency Graph (User Story Completion Order)

```mermaid
graph TD
    P1[Phase 1: Setup] --> P2[Phase 2: Foundational]
    P2 --> US1[Phase 3: User Story 1 - Get/Set (P1)]
    US1 --> US2[Phase 4: User Story 2 - Path Resolution (P1)]
    US2 --> US5[Phase 5: User Story 5 - Schema Driven (P1)]
    US5 --> US6[Phase 8: User Story 6 - JSON Configuration Loading (P1)]
    US6 --> US3[Phase 6: User Story 3 - Lifecycle Management (P2)]
    US3 --> US4[Phase 7: User Story 4 - Notifications (P2)]
    US4 --> Final[Final Phase: Polish & Cross-Cutting Concerns]
```

## Parallel Execution Examples

Tasks marked with `[P]` can be executed in parallel within their respective phases. For example, in Phase 4, the two `UspPath` enhancement tasks (T024, T025) can be worked on concurrently by different team members or processes. In Phase 8, T050, T051, T052 can be started in parallel if the interface is stable.

## Implementation Strategy

This project will adopt an incremental development strategy, prioritizing MVP (Minimum Viable Product).
The MVP will cover Phase 1 to Phase 3 (User Story 1 - Data Access), providing basic parameter read/write functionality.
Subsequent phases will sequentially integrate path resolution, schema-driven, JSON configuration loading, dynamic lifecycle management, and notification mechanisms.
Each User Story phase will be treated as an independent, testable increment, ensuring that each iteration delivers value.

## Summary of Tasks

*   **Total Task Count**: 61
*   **Tasks per User Story**:
    *   User Story 1 (Get/Set): 6 tasks
    *   User Story 2 (Path Resolution): 7 tasks
    *   User Story 5 (Schema Driven): 5 tasks
    *   User Story 6 (JSON Configuration Loading): 6 tasks
    *   User Story 3 (Lifecycle Management): 6 tasks
    *   User Story 4 (Notifications): 8 tasks
*   **Parallel Opportunities Identified**: 3 (within Phase 4 for `UspPath` enhancements; within Phase 8 for `JsonConfigLoader` implementation)
*   **Independent Test Criteria for each Story**: Defined in respective User Story sections.
*   **Suggested MVP Scope**: Phase 1 (Setup) + Phase 2 (Foundational) + Phase 3 (User Story 1 - Data Access).