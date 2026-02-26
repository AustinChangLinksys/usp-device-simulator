<!--
Sync Impact Report:
- Version change: 0.0.0 -> 1.0.0
- Added Sections:
  - 1. Vision & Mission
  - 2. Core Principles
    - 2.1 The Neutrality Rule
    - 2.2 The Purity Rule
    - 2.3 The Stateless Rule
  - 3. Internal Structure & Responsibilities
    - Module A: Domain Primitives
    - Module B: Protocol Contracts
    - Module C: Wire Format
    - Module D: Tools & Converters
  - 4. Boundaries (What is Out of Scope)
  - 5. Governance
- Removed Sections:
  - All previous placeholder sections.
- Templates requiring updates:
  - .specify/templates/plan-template.md (✅ updated)
  - .specify/templates/spec-template.md (✅ updated)
  - .specify/templates/tasks-template.md (✅ updated)
- Follow-up TODOs:
  - TODO(RATIFICATION_DATE): Determine the original adoption date of the constitution.
-->
# Constitution for usp_protocol_common

## 1. Vision & Mission
usp_protocol_common aims to serve as the Single Source of Truth within the USP (User Services Platform / TR-369) ecosystem.

The mission of this library is to define the Communication Contract and Shared Language between the Client (Controller) and the Server (Agent). It ensures that applications on both ends can exchange information precisely and with type safety, while remaining completely decoupled and independent of implementation details.

## 2. Core Principles
All code contributed to this library must strictly adhere to the following three principles:

### 2.1 The Neutrality Rule
This library does not know and does not care whether it is running on a Client or a Server. It is responsible solely for defining data formats and translation logic, never containing business decisions specific to a role (e.g., permission checks or state maintenance).

### 2.2 The Purity Rule
This library must be a Pure Dart Package to ensure maximum portability.

**FORBIDDEN**: Dependency on the flutter SDK (UI logic).

**FORBIDDEN**: Dependency on `dart:io` (File/Socket) or `dart:html` (Browser DOM).

**GOAL**: Ensure this package runs seamlessly in Dart VM (Server/CLI), Flutter Mobile, Flutter Desktop, and Flutter Web environments.

### 2.3 The Stateless Rule
This library contains only Data Structures, Interfaces, and Pure Functions.

All utilities and converters must be stateless.

**FORBIDDEN**: Holding any application runtime state (e.g., Session Cache or Device Tree).

## 3. Internal Structure & Responsibilities
The library is divided into four logical modules, each with specific responsibilities:

### 🧱 Module A: Domain Primitives
**Path**: `lib/src/value_objects/`

**Contents**: `UspPath`, `UspValue`, `UspValueType`, `InstanceId`.

**Responsibility**: Defines the most basic atomic units of the USP protocol.

**Standards**: All objects must be Immutable, implement `Equatable` and `json_serializable`, and perform format validation upon construction (Fail Fast).

### 📜 Module B: Protocol Contracts
**Path**: `lib/src/dtos/`, `lib/src/exceptions/`

**Contents**: Request/Response DTOs (e.g., `UspGetRequest`), `UspException`.

**Responsibility**: Defines high-level standard formats for information exchange at the application layer, acting as carriers across architectural boundaries.

**Standards**: DTOs must be pure data classes containing no business logic.

### 🔌 Module C: Wire Format
**Path**: `lib/src/generated/`, `protos/`

**Contents**: Original `.proto` files and generated Dart code (`usp_msg.pb.dart`, `usp_record.pb.dart`).

**Responsibility**: Serves as the serialization definition for the USP standard (TR-369).

**Standards**: Generated code is considered read-only and must not be manually modified.

### 🛠️ Module D: Tools & Converters
**Path**: `lib/src/converter/`, `lib/src/services/`, `lib/src/interfaces/`

**Contents**: `UspProtobufConverter`, `UspRecordHelper`, `PathResolver`, `ITraversableNode`.

**Responsibility**:
- Handle bidirectional conversion between DTOs (High-level objects) and Proto (Transport objects).
- Provide generic algorithmic logic (e.g., Path Resolution), but must rely on Abstract Interfaces (DIP) rather than concrete implementations.

## 4. Boundaries (What is Out of Scope)
To ensure architectural purity, the following contents are strictly prohibited in this library:

### 🈲 Zone 1: Business Logic
- No logic for maintaining the DeviceTree.
- No side-effect implementations for Add, Delete, or Set operations on nodes.
- No permission validation logic (e.g., `isWritable`).

### 🈲 Zone 2: Persistence
- No Repository implementations.
- No code for database connections or file reading/writing.

### 🈲 Zone 3: Transport Implementation
- No concrete connection code for MQTT Client, WebSocket Client, or HTTP Client.
- This library handles packet Content and Wrapping, not packet Delivery.

### 🈲 Zone 4: Internal Events
- No definitions for Server-internal Notification Stream or Event Bus.

## 5. Governance
**Version Control**: All Protocol changes (modifying `.proto` files) must be completed within this package, followed by code regeneration. Private modification of generated code in the App layer is prohibited.

**Testing Requirements**: All Converters and Resolvers must have high code coverage unit tests to ensure the correctness of translation logic.

**Documentation**: All DTOs and Public APIs must include DartDoc comments explaining their corresponding sections in the USP specification.

---
**Version**: 1.0.0 | **Ratified**: 2025-11-23 (Placeholder - update with actual date) | **Last Amended**: 2025-11-22