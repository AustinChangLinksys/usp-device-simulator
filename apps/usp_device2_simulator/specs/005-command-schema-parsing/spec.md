# Feature Specification: Command Node & Schema Parsing

**Feature Branch**: `005-command-schema-parsing`
**Created**: 2025-11-26
**Status**: Draft
**Input**: User description: "Feature Specification: Command Node & Schema Parsing Target Project: apps/usp_device2_simulator Feature Phase: Phase 2-A (Operations) Dependencies: usp_protocol_common (for UspPath, UspValueType) Status: Ready for Implementation 1. Executive Summary
This feature aims to enable the Simulator to fully parse the `<command>` tags in TR-181 XML and instantiate them as `UspCommandNode` entities with metadata. This is a prerequisite for implementing Phase II Operate commands. 2. Data Model Definition (New Entity) 我們需要一個新的實體來表示樹上的指令節點： Key Entity: UspCommandNode Purpose: Represents an executable function/command in the DeviceTree. Inheritance: Extends UspNode. Properties: isCommand (bool): true. isAsync (bool): Derived from XML's commandType attribute (asynchronous). inputArgs: Map<String, UspArgumentDefinition> (Metadata for input). outputArgs: Map<String, UspArgumentDefinition> (Metadata for output). Helper DTO: UspArgumentDefinition (for Metadata) Contents: String name, UspValueType type. 3. Functional Requirements (FR) FR-01: Command Parsing and Node Creation FR-01.1: The XmlSchemaLoader MUST implement a parsing pass for all <command> tags found in the XML model. FR-01.2: For each <command>, the loader MUST instantiate a UspCommandNode and attach it to its parent UspObject's children map. FR-01.3: The Loader MUST correctly derive the isAsync flag from the XML's commandType attribute (if present and set to 'asynchronous'). FR-02: Argument Metadata Extraction (GetSupportedDM Support) FR-02.1: The Loader MUST implement a reusable helper function (_parseArguments) to traverse the nested <input> and <output> blocks within the <command> tag. FR-02.2: The parser MUST extract the name and the derived UspValueType (parsed from the nested <syntax> tag) for every argument. FR-02.3: The resulting argument maps (inputArgs, outputArgs) must be stored within the UspCommandNode instance. FR-02.4: The parsing must be robust against missing optional blocks (e.g., a command may have input but no output). 4. Acceptance Criteria (Testing) AC-01: Correct Node Type and Structure Setup: Load a minimal schema containing Device.Reboot() and Device.IP.Diagnostics.IPPing(). Verification: The node resolved at Device.Reboot MUST be an instance of UspCommandNode. Device.Reboot.isParameter MUST be false. Device.Reboot.isAsync MUST be false (Reboot is typically synchronous or fires immediately). AC-02: Argument Metadata Integrity Setup: Load a schema containing a complex command (e.g., IPPing with input/output). Verification: IPPing.inputArgs map MUST contain the correct number of entries (e.g., {'Host': UspArgumentDefinition, 'Count': UspArgumentDefinition}). The Host argument's UspValueType MUST be correctly mapped (e.g., UspValueType.string). If the command requires no arguments, the inputArgs map MUST be empty ({}). AC-03: Loader Integration The main XmlSchemaLoader.loadSchema method must include a dedicated parsing pass for commands, correctly attaching them to their parent UspObject before the Bottom-Up hierarchy build (Pass 3)."

## Executive Summary

This feature enables the simulator to parse `<command>` tags from a TR-181 XML data model, instantiating them as `UspCommandNode` entities within the device's object tree. This includes extracting all associated metadata for input and output arguments, which is a prerequisite for implementing USP Operate commands.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Command Node Creation (Priority: P1)

As a developer, I want the system to correctly parse XML `<command>` tags and create the corresponding `UspCommandNode` in the device tree, so that commands are represented accurately in the data model.

**Why this priority**: This is the fundamental step for representing commands. Without it, no command-related functionality can be implemented.

**Independent Test**: This can be tested by loading a schema with at least one command and verifying that the corresponding node is created with the correct type and properties in the device tree.

**Acceptance Scenarios**:

1.  **Given** a TR-181 XML schema containing the `Device.Reboot()` command.
2.  **When** the `XmlSchemaLoader` processes the schema.
3.  **Then** the node at the path `Device.Reboot` MUST be an instance of `UspCommandNode`.
4.  **And** the `isParameter` property of the `Device.Reboot` node MUST be `false`.
5.  **And** the `isAsync` property of the `Device.Reboot` node MUST be `false`.

---

### User Story 2 - Command Argument Extraction (Priority: P2)

As a developer, I want the system to parse the input and output arguments of a `<command>` tag, so that the command's signature and metadata are available for validation and execution.

**Why this priority**: This provides the necessary metadata for other parts of the system (like a `GetSupportedDM` response or a command execution engine) to understand how to interact with the command.

**Independent Test**: This can be tested by loading a schema with a command that has input and output arguments and verifying that the `inputArgs` and `outputArgs` properties of the `UspCommandNode` are populated correctly.

**Acceptance Scenarios**:

1.  **Given** a TR-181 XML schema containing a command with defined input and output arguments (e.g., `Device.IP.Diagnostics.IPPing()`).
2.  **When** the `XmlSchemaLoader` processes the schema.
3.  **Then** the `IPPing` node's `inputArgs` map MUST contain entries for each defined input argument (e.g., 'Host', 'Count').
4.  **And** each argument definition in the map MUST have the correct name and `UspValueType` (e.g., the 'Host' argument's type is `UspValueType.string`).
5.  **Given** a command with no defined input arguments.
6.  **When** the schema is loaded.
7.  **Then** the corresponding `UspCommandNode`'s `inputArgs` map MUST be empty.

---

### User Story 3 - Loader Integration (Priority: P3)

As a developer, I want the command parsing logic to be correctly integrated into the main schema loading process, so that commands are reliably loaded along with objects and parameters.

**Why this priority**: Ensures the feature is a robust part of the system, not a standalone process.

**Independent Test**: Can be tested by ensuring the command parsing pass happens at the correct stage of the overall `loadSchema` execution.

**Acceptance Scenarios**:

1.  **Given** the `XmlSchemaLoader`.
2.  **When** the `loadSchema` method is executed.
3.  **Then** a parsing pass dedicated to `<command>` tags MUST be executed.
4.  **And** the created `UspCommandNode` instances MUST be attached to their parent `UspObject` before the final hierarchy build pass (Pass 3) occurs.

### Edge Cases

- A `<command>` tag is present but has no `<input>` or `<output>` blocks. The system should handle this gracefully, resulting in empty `inputArgs` and `outputArgs` maps.
- An argument's `<syntax>` tag contains a data type that does not map to a `UspValueType`. The system should handle this error, possibly by logging a warning and skipping the argument.
- The `commandType` attribute is missing or has a value other than 'asynchronous'. The `isAsync` flag should default to `false`.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The `XmlSchemaLoader` MUST implement a parsing pass for all `<command>` tags within the provided XML data model.
- **FR-002**: For each `<command>` tag, the loader MUST instantiate a `UspCommandNode` and add it to its parent `UspObject`'s collection of child nodes.
- **FR-003**: The `isAsync` flag on the `UspCommandNode` MUST be set to `true` if the XML's `commandType` attribute is 'asynchronous', and `false` otherwise.
- **FR-004**: The loader MUST parse the `<input>` and `<output>` blocks within each `<command>` to extract argument metadata.
- **FR-005**: For each argument, the parser MUST extract its name and derive its `UspValueType` from the nested `<syntax>` tag.
- **FR-006**: The extracted argument metadata MUST be stored in the `inputArgs` and `outputArgs` maps within the corresponding `UspCommandNode` instance.

### Key Entities

- **UspCommandNode**: Represents an executable function/command in the DeviceTree. It extends `UspNode` and contains metadata about its execution behavior (synchronous/asynchronous) and its input/output arguments.
- **UspArgumentDefinition**: A Data Transfer Object (DTO) that holds the metadata for a single command argument, including its `name` and `UspValueType`.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of `<command>` tags in a standard TR-181 XML file are successfully parsed and converted into `UspCommandNode` instances in the device tree.
- **SC-002**: For all parsed commands, the argument metadata (name and type) for 100% of their input and output arguments is accurately captured.
- **SC-003**: When `GetSupportedDM` is called on a device model loaded with commands, the response correctly includes the command names and their associated argument details.
- **SC-004**: The schema loading time must not increase by more than 15% compared to the baseline before this feature was implemented.