# Implementation Plan: Command Node & Schema Parsing

**Feature Branch**: `005-command-schema-parsing`
**Created**: 2025-11-26
**Status**: Draft

## Technical Context

The project is the USP Device:2 Simulator, which is built following the Clean Architecture principles. This implementation focuses on modifying the Infrastructure layer, specifically the `XmlSchemaLoader`, to support parsing of `<command>` tags from TR-181 compliant XML data models.

This feature is a prerequisite for the full `Operate` command implementation (Phase 2-A), as it builds the necessary in-memory representation of device commands and their argument metadata. The primary dependency is on the existing `xml` package for XML parsing and the `usp_protocol_common` package which may contain shared entities (to be verified).

## Phasing Strategy & Tasks Breakdown

### Phase 1: Entity Definition & Structure

*   **Goal**: Define the necessary domain structures to hold command metadata (Input/Output argument definitions).
*   **Tasks**:
    1.  **Implement `UspArgumentDefinition`**: Create a new DTO class to store argument metadata (`name`, `UspValueType`). This will reside in the `domain/entities` directory.
    2.  **Implement `UspCommandNode`**: Create the main entity class inheriting from `UspNode`. It will be responsible for storing the argument maps (`inputArgs`, `outputArgs`) and the `isAsync` flag. This will also reside in the `domain/entities` directory.
    3.  **Unit Tests for Entities**: Implement unit tests for `UspCommandNode` to verify its constructor and basic properties.

### Phase 2: XML Parsing Logic & Loader Integration

*   **Goal**: Implement the robust, recursive logic to extract command arguments and integrate the parsing pass into the main `XmlSchemaLoader`.
*   **Tasks**:
    1.  **Implement `_parseArguments` helper**: In `XmlSchemaLoader`, create a private helper function that takes an XML element (either `<input>` or `<output>`) and returns a `Map<String, UspArgumentDefinition>`. This function will be responsible for iterating through `<parameter>` children and extracting their name and syntax.
    2.  **Implement `_parseCommandElement` method**: In `XmlSchemaLoader`, create a method that processes a single `<command>` XML element. It will use `_parseArguments` to build the `inputArgs` and `outputArgs` maps and construct a `UspCommandNode` instance.
    3.  **Integrate Command Parsing Pass**: Modify the main `loadSchema` method in `XmlSchemaLoader` to include a new parsing pass (e.g., Pass 2.5) that iterates over all `<command>` elements and calls `_parseCommandElement`. This pass must run after objects (Pass 2) are parsed but before the hierarchy is built (Pass 3), ensuring commands are attached to their parent objects correctly.

### Phase 3: Acceptance & Quality Gate

*   **Goal**: Verify the integrity of the loader and ensure full coverage of the new logic before proceeding to dependent features.
*   **Tasks**:
    1.  **Create Integration Tests**: Develop a new test file (`xml_schema_loader_command_test.dart`) to verify the end-to-end command parsing logic. This test should load a mock XML schema containing commands with and without arguments (e.g., `Device.Reboot`, `Device.IP.Diagnostics.IPPing`).
    2.  **Verify Acceptance Criteria**: The integration test must assert that `AC-01` and `AC-02` from the feature specification are met (e.g., correct node type, correct argument count and types in `inputArgs`).
    3.  **Run Code Coverage**: Execute the test suite and ensure the quality gate for code coverage is met.

## Quality Gate Requirements

1.  **Test Coverage**: All new logic, including `UspCommandNode`, `UspArgumentDefinition`, and the new parsing methods within `XmlSchemaLoader`, must achieve a **minimum of 90% code coverage**.
2.  **Acceptance Criteria Verification**: All acceptance criteria outlined in the feature specification must be demonstrated to pass via automated tests. For example, a test must verify that `Device.IP.Diagnostics.IPPing.inputArgs` contains the correct type and number of arguments as defined in the test schema.
3.  **Static Analysis**: The code must pass all existing linting and static analysis checks without any new warnings or errors.