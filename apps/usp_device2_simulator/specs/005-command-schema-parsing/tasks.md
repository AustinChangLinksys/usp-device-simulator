# Actionable Tasks: Command Node & Schema Parsing

This document breaks down the implementation plan into a series of actionable, dependency-ordered tasks that can be executed to complete the feature.

## Implementation Strategy

The implementation will follow the phases outlined in the plan, which are aligned with the user stories from the specification. This allows for incremental development and testing.

1.  **Foundational**: First, we will define the core data structures (`UspCommandNode`, `UspArgumentDefinition`) that are prerequisites for any further logic.
2.  **User Story 1 & 2**: Next, we will implement the core parsing logic within `XmlSchemaLoader` to populate these new data structures.
3.  **User Story 3**: Finally, we will write integration tests to verify that the end-to-end process works as expected and meets all acceptance criteria.

This approach ensures that the domain entities are sound before building the more complex parsing logic and that the entire feature is validated before being considered complete.

## Task Checklist

### Phase 1: Foundational Entity Implementation

These tasks are the prerequisite for all other work and align with the goal of **User Story 1**.

- [x] T001 Create the argument definition DTO in `lib/domain/entities/usp_argument_definition.dart`
- [x] T002 Create the command node entity in `lib/domain/entities/usp_command_node.dart`
- [x] T003 [P] Create unit tests for the new entities in `test/domain/entities/usp_command_node_test.dart`

### Phase 2: Core Parsing Logic

These tasks implement the main parsing logic required for **User Story 2**.

- [x] T004 [US2] Implement the `_parseArguments` helper function in `lib/infrastructure/schema/xml_schema_loader.dart`
- [x] T005 [US2] Implement the `_parseCommandElement` method in `lib/infrastructure/schema/xml_schema_loader.dart`

### Phase 3: Integration and Verification

These tasks complete the feature by integrating the new parsing pass and verifying its correctness, aligning with **User Story 3**.

- [x] T006 [US3] Integrate the command parsing pass into the `loadSchema` method in `lib/infrastructure/schema/xml_schema_loader.dart`
- [x] T007 [US3] Create integration tests in `test/infrastructure/schema/xml_schema_loader_command_test.dart` to verify AC-01 and AC-02.

### Phase 4: Polish & Cross-Cutting Concerns

- [x] T008 Review and refactor new code for clarity and adherence to project conventions.
- [x] T009 Run `dart analyze` to ensure no new linting issues have been introduced.
- [x] T010 Run the full test suite with coverage and verify the 90% coverage gate is met for all new files.
- [x] T011 Implement performance benchmark for `XmlSchemaLoader.loadSchema` to verify SC-004 in `test/infrastructure/schema/xml_schema_loader_performance_test.dart`
- [x] T012 Modify `bin/verify_transport_grpc.dart`, `bin/verify_transport_mqtt.dart`, and `bin/verify_transport_ws.dart` to verify command metadata using a `GetSupportedDM` request on a command (e.g., `Device.Test.MyCommand()`).

## Dependencies

-   **Phase 2** depends on the completion of **Phase 1**.
-   **Phase 3** depends on the completion of **Phase 2**.

User Stories can be seen as largely sequential in this plan: US1 (foundations) -> US2 (parsing logic) -> US3 (integration/verification).

## Parallel Execution

Within each phase, some tasks can be parallelized:
- **Phase 1**: `T003` (unit tests) can be written in parallel with `T001` and `T002` if a TDD approach is taken.
- Other phases are sequential due to direct dependencies.
