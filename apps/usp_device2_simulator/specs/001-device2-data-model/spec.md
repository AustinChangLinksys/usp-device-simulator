# Feature Specification: TR-181 Device:2 Data Model Engine

**Feature Branch**: `001-device2-data-model`  
**Created**: 2025-11-21  
**Status**: Draft  
**Input**: User description: "1. Executive Summary: This project aims to develop a high-performance, high-fidelity TR-181 Device:2 data model engine (i.e., "high-fidelity" simulation). It will serve as the core component of a USP Agent, responsible for handling complex data structures, path resolution, parameter validation, and state lifecycle. Unlike simple Mock Servers, this engine will be "Contract-Aware," capable of strictly enforcing USP protocol specifications based on its definitions. 2. Architectural Specification: We adopt Clean Architecture, dividing the system into three concentric layers, with dependencies flowing inward. 2.1 Domain Layer (Core Domain Layer): Responsibilities: Define USP business rules, entities, and behavior contracts. Dependencies: Pure Dart, no dependencies on external frameworks like Flutter, Riverpod, Http. Key Components (DDD): Aggregate Root: DeviceTree (responsible for maintaining the consistency of the entire tree). Entities: UspNode, UspObject, UspParameter, UspCommand. Value Objects: UspPath (path logic), UspValue (type encapsulation), InstanceId. Failures: UspException (corresponding to TR-369 Error Codes). Repository Interface: IDeviceRepository. 2.2 Application Layer: Responsibilities: Orchestrate Domain Objects to complete specific use cases. Dependencies: Depends on the Domain Layer. Key Components (Use Cases): GetParameterValue, SetParameterValue (includes DBC validation process), AddObject / DeleteObject, Operate (Async Command execution). 2.3 Infrastructure Layer: Responsibilities: Implement interfaces, manage state persistence, integrate external frameworks. Dependencies: Depends on the Application and Domain Layers. Key Components: State Management: DeviceRepositoryImpl. Data Sources: XmlSchemaLoader (parses TR-181 XML), JsonPersistenceService. 3. Domain Model Specification: 3.1 Design-by-Contract (DBC) Implementation Strategy: All data modification operations must satisfy the following contracts; otherwise, a UspException will be thrown: Preconditions: Path must exist (Error 7002). Parameter must be writable (Error 7003/7004). Value type must be correct (Error 7003). Value must be within defined range (Range/Pattern) (Error 7003). Postconditions: Reading the new value of the node must equal the value just written. For AddObject, node count must increase by +1. Invariants: Parent-Child Relationship cannot be broken. Read-only parameters (e.g., Manufacturer) cannot be changed at Runtime. 3.2 Entity Definitions: UspNode: Base class for all nodes, includes path, name, attributes (map). UspParameter: Generic T, holds value, has validate(T value) method. MultiInstanceObject: Special UspObject, holds NextInstanceId counter and InstanceMap. 4. Functional Requirements FR-1: Data Access (Get/Set): The system must support reading and writing parameters via Full Path. The system must support reading via Partial Path (returning a subtree). The system must implement a complete USP error code response mechanism. FR-2: Path Resolution: Support direct lookup for Device.WiFi.Radio.1.Status. Support wildcard lookup for Device.WiFi.Radio.*.Status, returning a list. Support alias filtering for Device.WiFi.SSID.[Alias=="Guest"].Enable."

## User Scenarios & Testing

### User Story 1 - Data Access (Get/Set) (Priority: P1)

Users need to read and write parameters in the Device:2 data model via full or partial paths.

**Why this priority**: This is the most core functionality, forming the basis for interaction with the USP Agent.

**Independent Test**: By simulating USP Get/Set requests, verify that the returned parameter values and error codes conform to expectations.

**Acceptance Scenarios**:

1.  **Given** the device is initialized and the data model is loaded, **When** calling GetParameterValue UseCase with a full UspPath, **Then** the system should return the correct parameter value.
2.  **Given** the device is initialized and the data model is loaded, **When** calling SetParameterValue UseCase with a full UspPath and a valid value, **Then** the system should successfully update the parameter value, and subsequent GetParameterValue UseCase calls should return the new value.
3.  **Given** the device is initialized and the data model is loaded, **When** calling GetParameterValue UseCase with a partial UspPath, **Then** the system should return the corresponding subtree structure.
4.  **Given** the device is initialized and the data model is loaded, **When** calling SetParameterValue UseCase, but the path does not exist or the parameter is not writable, **Then** the system should return the corresponding USP error code (e.g., 7002, 7003, 7004).

### User Story 2 - Path Resolution (Priority: P1)

The system needs to be able to accurately resolve various path formats defined in the USP protocol, including wildcards and aliases.

**Why this priority**: Correct path resolution is crucial for data access and operations, directly impacting system usability.

**Independent Test**: By providing UspPath objects with various wildcard/alias patterns, verify that the system correctly resolves and locates target nodes or lists of nodes.

**Acceptance Scenarios**:

1.  **Given** the data model contains the Device.WiFi.Radio.1.Status node, **When** the user sends a Get request with the path "Device.WiFi.Radio.1.Status", **Then** the system should directly find and return the value of that node.
2.  **Given** the data model contains multiple Device.WiFi.Radio.*.Status nodes, **When** the user sends a Get request with the path "Device.WiFi.Radio.*.Status", **Then** the system should return a list of all matching nodes.
3.  **Given** the data model supports alias lookup, **When** the user sends a Get request with the path "Device.WiFi.SSID.[Alias=="Guest"].Enable", **Then** the system should look up and return the value of the corresponding node based on the alias.

### User Story 3 - Dynamic Lifecycle Management (Priority: P2)

The system needs to support dynamic addition and deletion of multi-instance objects in the data model.

**Why this priority**: Dynamic lifecycle management is crucial for simulating real device behavior, such as adding or removing WiFi networks.

**Independent Test**: By simulating AddObject and DeleteObject operations, verify that objects are correctly added/deleted and their Instance IDs are assigned as expected.

**Acceptance Scenarios**:

1.  **Given** a multi-instance object exists in the data model, **When** the user sends an AddObject request, **Then** the system should automatically assign a unique Instance ID and instantiate a new subtree based on the Schema Template.
2.  **Given** an existing multi-instance object instance in the data model, **When** the user sends a DeleteObject request, **Then** the system should remove that instance and all its child nodes, and trigger cleanup logic.

### User Story 4 - State Notifications (Priority: P2)

The system should issue notifications when parameter values change or objects are added/deleted.

**Why this priority**: The notification mechanism is a key part of the USP protocol, allowing the Controller to monitor device state changes.

**Independent Test**: By subscribing to notification events, verify that the correct notifications are issued after specific operations, and that the notification content is accurate.

**Acceptance Scenarios**:

1.  **Given** the value of a UspParameter is modified, **When** the SetParameterValue operation is complete, **Then** the system should issue a ValueChangeNotification containing the Path, OldValue, and NewValue.
2.  **Given** a new object is successfully added, **When** the AddObject operation is complete, **Then** the system should issue an ObjectCreationNotification.
3.  **Given** an object is successfully deleted, **When** the DeleteObject operation is complete, **Then** the system should issue an ObjectDeletionNotification.

### User Story 5 - Schema Driven (Priority: P1)

The system should be able to dynamically parse standard TR-181 XML Schema and construct the data model, rather than using hardcoded structures.

**Why this priority**: Schema-driven is the foundation for high flexibility and coverage, reducing manual maintenance costs and ensuring standard compliance.

**Independent Test**: By providing different TR-181 XML Schema files, verify that the system correctly parses and constructs the corresponding in-memory data model.

**Acceptance Scenarios**:

1.  **Given** a valid TR-181 XML Schema file, **When** the system starts and loads the Schema, **Then** the system should automatically construct the corresponding Device:2 data model in memory.
2.  **Given** an invalid or malformed TR-181 XML Schema file, **When** the system attempts to load the Schema, **Then** the system should throw a clear error message indicating Schema parsing failure.
3.  **Given** the Schema is successfully loaded, **When** checking the data model structure, **Then** the model should contain all objects, parameters, and commands defined in the XML Schema, with correct attributes.

### User Story 6 - JSON Configuration Loading (Priority: P1)

The system should support loading configurations from JSON files and using their values to override default values loaded from the XML Schema.

**Why this priority**: JSON configuration provides flexible data model customization capabilities, allowing adjustment of parameter default values without modifying the Schema.

**Independent Test**: After loading the XML Schema, load the JSON configuration, and verify that the overridden values for selected parameters are correct.

**Acceptance Scenarios**:

1.  **Given** the system has loaded the data model from a TR-181 XML Schema, and a valid JSON configuration file exists, **When** the system starts and loads the JSON configuration, **Then** the system should successfully apply the values from the JSON configuration, overriding the default values of corresponding parameters in the data model.
2.  **Given** the system has loaded the data model from a TR-181 XML Schema, and the JSON configuration file contains invalid paths or parameters with mismatched value types, **When** the system attempts to load the JSON configuration, **Then** the system should throw a clear error message indicating configuration loading failure, and should not affect the loading of other valid configurations.
3.  **Given** the system has loaded the data model from a TR-181 XML Schema, **When** loading the JSON configuration, **Then** the JSON configuration should not modify the `Writable` attribute of parameters.

### Edge Cases

- Behavior of Get/Set operations when path resolution returns multiple matches? (Default: Get returns a list, Set operates on all matches)
- When the value type of a Set request does not match the Schema definition? (Default: Throw UspException error code 7003)
- When the Instance ID of a DeleteObject request does not exist? (Default: Throw UspException)
- When SchemaLoader encounters non-standard or parsing-failed XML structures? (Default: Throw parsing error and stop startup)

## Requirements

### Functional Requirements

-   **FR-001**: The system must support reading and writing parameters via full paths, e.g., direct lookup of "Device.WiFi.Radio.1.Status".
-   **FR-005**: The system must support wildcard lookups like "Device.WiFi.Radio.*.Status" and return a matching list.
-   **FR-006**: The system must support alias lookups, e.g., "Device.WiFi.SSID.[Alias=="Guest"].Enable".
-   **FR-007**: The system must automatically assign a unique Instance ID for newly added multi-instance objects.
-   **FR-008**: The system must instantiate the subtree for newly added multi-instance objects according to the Schema Template.
-   **FR-009**: The system must remove the specified instance and all its child nodes.
-   **FR-010**: When parameter values change, the system must issue notifications containing old and new values, and the path.
-   **FR-011**: When a new object is created, the system must issue relevant notifications.
-   **FR-012**: When an object is removed, the system must issue relevant notifications.
-   **FR-013**: The system must be able to read standard TR-181 XML format definition files.
-   **FR-014**: The system must dynamically construct the in-memory data model upon startup, without relying on hardcoded structures.
-   **FR-015**: All data modification operations must adhere to predefined rules (Design-by-Contract); otherwise, the system should throw an error.
-   **FR-016**: The system must support loading configurations from a specified JSON file, and use its values to override default values loaded from the XML Schema.

### Key Entities

-   **DeviceTree**: As an Aggregate Root, responsible for maintaining the hierarchical structure and consistency of the entire TR-181 data model.
-   **UspNode**: A common base class for all elements in the data model, including path, name, and attributes.
-   **UspObject**: Represents an object node in the data model, which can contain child objects, parameters, and commands.
-   **UspParameter**: Represents a parameter node in the data model, possessing a value and validation rules.
-   **UspCommand**: Represents an executable operation in the data model.
-   **UspPath**: A value object (from `usp_protocol_common`) for handling path logic in the USP protocol.
-   **UspValue**: A value object (from `usp_protocol_common`) for encapsulating the data type and content of a parameter. Its `type` attribute can be `UspValueType.string`, `UspValueType.int`, `UspValueType.unsignedInt`, `UspValueType.long`, `UspValueType.unsignedLong`, `UspValueType.boolean`, etc.
-   **InstanceId**: A value object (from `usp_protocol_common`) used to identify specific instances within multi-instance objects.
-   **UspException**: An exception (from `usp_protocol_common`) thrown by the system when handling errors, containing TR-369 error codes.
-   **Device Data Access Interface**: Defines the abstract contract for operations on the DeviceTree.
-   **XML Schema Loader**: Responsible for parsing TR-181 XML Schema and converting it into the internal data model structure.
-   **JsonConfigLoader**: Responsible for reading JSON files, parsing configuration data, and applying it to the data model to override existing default values.
-   **Data Persistence Service**: Responsible for storing and restoring the state of the data model.

## Success Criteria

### Measurable Outcomes

-   **SC-001**: Domain Layer logic test coverage achieves over 90%.
-   **SC-002**: The system passes basic USP Protocol simulation tests (Get/Set/Add/Delete) and error codes comply with TR-369 standards.
-   **SC-003**: Loading the complete tr-181-2-16-0.xml model and starting the service must complete within 2 seconds.
-   **SC-004**: The system must successfully parse at least one officially provided TR-181 XML Schema and correctly construct the data model.
-   **SC-005**: Each parameter value change and object add/delete operation must trigger the correct notification event.
-   **SC-006**: When DBC preconditions are violated (e.g., writing to a read-only parameter), the system must throw a specific USP exception (domain failure).

## Assumptions

-   Other components of the USP Agent (e.g., message transport layer, data serialization/deserialization, user interface) will be handled externally or implemented in other projects. This project is not responsible for their development.
-   TR-181 XML Schema file format is standard and valid. This project will parse based on this premise.
-   Specific implementation details of the persistence mechanism (independent storage and recovery of configuration and state) will be determined in subsequent designs.
-   "Real" Device:2 simulation environment primarily refers to data model behavior simulation, not device hardware behavior simulation.
-   Error handling in Design-by-Contract (DBC) will throw specific error exceptions, including standard error codes.

## Clarifications

### Session 2025-11-21

- Q: Should the "Key Entities" section explicitly use the proposed class names (DeviceTree, UspNode, UspValue, UspPath) to align with the Domain Driven Design principles and terminology? → A: Yes, align with proposed class names.
- Q: How should the acceptance scenarios for data access be phrased to emphasize testing of "Pure Dart" Domain Logic (e.g., direct use case calls) rather than implying external "requests"? → A: Rephrase to "When calling [UseCase] and passing [DomainObject]..."
- Q: Should a new success criterion (SC-006) be added to explicitly state that the system must throw a specific `UspException` (domain failure) when a precondition is violated (e.g., writing to a read-only parameter)? → A: Yes, add SC-006 as proposed.

## Out of Scope

-   **Message Transport Layer Details**: This project focuses on the "service layer" and does not include underlying connection implementations (e.g., WebSocket/MQTT/STOMP).
-   **Data Serialization/Deserialization**: This project receives/returns internal application data objects; serialization is handled by external adapters.
-   **User Interface**: This project is a headless service and does not include any graphical user interface.