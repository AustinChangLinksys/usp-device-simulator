# USP Device:2 High-Fidelity Simulator Core Constitution

## 1. Vision & Mission

**Vision:**
To create a high-fidelity, architecturally rigorous, and strictly compliant core for a USP (User Services Platform) Agent based on Broadband Forum TR-369 and TR-181 standards.

**Mission:**
* **Simulation:** Provide a "Real" Device:2 simulation environment capable of validating complex Controller logic.
* **Architecture:** Establish a best-practice template using **Dart** and **Clean Architecture**, demonstrating the value of **DDD (Domain-Driven Design)** and **DBC (Design by Contract)** in complex protocol implementations.
* **Automation:** Achieve maximum model coverage through **Schema-Driven** technology (parsing standard XML) rather than hard-coding thousands of parameters.

## 2. Objectives

The success of this project is defined by the following key objectives:

1.  **Compliance:** Full support for the TR-181 Issue 2 data model structure, including Objects, Parameters, Multi-Instance tables, and Commands.
2.  **Architectural Purity:** Strict adherence to **Clean Architecture**. The Domain Layer must remain pure Dart, independent of external frameworks (Flutter/Riverpod), ensuring testability and portability.
3.  **Robustness:** rigorous enforcement of **DBC** (Preconditions, Postconditions, Invariants) to ensure data model consistency. Errors must map correctly to USP Protocol Error Codes.
4.  **Automation:** Capability to dynamically parse official TR-181 XML Schemas to construct the internal memory model, coupled with **Smart Provisioning** for auto-instantiation from configuration files.

## 3. Technical Stack & Standards

| Domain | Selection / Standard |
| :--- | :--- |
| **Language** | **Dart** (SDK >= 3.0) |
| **State Management** | **Riverpod** (v2.x) - Using NotifierProvider & Immutable State |
| **Architecture** | **Clean Architecture** (Domain / Application / Infrastructure) |
| **Design Pattern** | **DDD** (Aggregate Root, Value Objects), **DBC** (Fail Fast) |
| **Protocol** | **TR-369** (USP), **TR-181 Issue 2** (Device:2 Data Model) |
| **Serialization** | `protobuf` (Network Wire Format), `json_serializable` (Config) |
| **Data Source** | `xml` (Schema Parsing) |

## 4. Modularization Strategy (Monorepo)

The project follows a strict **Monorepo** structure to separate the "Contract" from the "Implementation".

### 4.1 Shared Kernel (`packages/usp_protocol_common`)
* **Role**: The **Communication Contract**.
* **Responsibility**: Defines DTOs, Protobuf generated code, Value Objects (`UspPath`, `UspValue`), and stateless converters.
* **Constraint**: Must be **Pure Dart** and **Stateless**. No dependency on Server logic or UI.

### 4.2 Server Application (`apps/usp_device2_simulator`)
* **Role**: The **USP Agent**.
* **Responsibility**: Manages the `DeviceTree`, executes business rules, handles persistence, and manages MTP connections.
* **Constraint**: Depends on `usp_protocol_common`. No dependency on Flutter UI.

### 4.3 Client Application (`apps/usp_flutter_client`)
* **Role**: The **USP Controller**.
* **Responsibility**: Provides the UI for interacting with the Agent via standard USP messages.
* **Constraint**: Depends on `usp_protocol_common`.

## 5. Project Scope

### ✅ In-Scope
* **Data Model Engine**:
    * In-memory management of the `Device.` tree.
    * Implementation of USP CRUD logic (Get, Set, Add, Delete).
    * Async `Operate` command execution flow.
* **Path Resolution**:
    * Support for Full Paths, Partial Paths, and **Wildcards (`*`)**.
    * Recursive traversal algorithms (implemented via `ITraversableNode` interface).
* **Lifecycle Management**:
    * Dynamic Add/Delete of Multi-Instance Objects (`{i}`).
    * **Smart Provisioning**: Auto-creation of instances based on JSON configuration keys.
* **Communication**:
    * **MTP Services**: WebSocket Server and MQTT Client implementations.
    * **Protocol Handling**: Encoding/Decoding of USP Records and Messages (Protobuf).
* **Persistence**:
    * Separation of Configuration (Config) and State (Runtime Data).

### ❌ Out-of-Scope
* **E2E Session Context**: USP-layer End-to-End encryption is currently deferred. Security relies on MTP-layer TLS (WSS/MQTTS).
* **GUI for Server**: The Simulator is a Headless Service.

## 6. Roadmap & Milestones

### ✅ Phase I: Core Foundation & Data Model (Completed)
**Goal: Establish a Schema-driven core engine with synchronous CRUD capabilities.**
* **Schema Driven**: Implemented `XmlSchemaLoader` for standard TR-181 XML (`Device:2.16+`).
* **Smart Provisioning**: Implemented auto-instantiation from JSON config.
* **Protocol Compliance**: Finalized `usp_protocol_common` with Protobuf/DTOs.
* **Synchronous Operations**: Full support for Get/Set/Add/Delete with error reporting.
* **Architecture**: Established Clean Architecture and Monorepo structure.

### 🔜 Phase II: Asynchronous Operations & Event Notification
**Goal: Implement the USP `Operate` mechanism and active server-push capabilities.**
* **Async Commands**: Implement the workflow: Request $\rightarrow$ Response $\rightarrow$ Async Complete (Notify).
    * *Examples*: `Device.Reboot()`, `Device.IP.Interface.1.Reset()`.
* **Notification Engine**: Implement `NotificationService` to bridge internal Dart Streams to external USP `Notify` packets.
* **Subscription Mechanism**: Implement lookup logic for **`Device.USPAgent.Subscription`** to support active push for `ValueChange` and `OperationComplete`.

### 🔒 Phase III: Security & Access Control (RBAC)
**Goal: Implement TR-369 compliant Authentication and Authorization.**
* **Endpoint Authorization**: Interceptor at the Adapter layer to verify `from_id`.
* **Controller Management**: Implement **`Device.USPAgent.Controller.{i}`** whitelist.
* **RBAC**: Restrict permissions based on Controller Roles.
* *(Optional) MTP Security*: Support WSS/MQTTS.

## 7. Guiding Principles

1.  **Domain First**: Core business logic must reside in `lib/domain` (Pure Dart). Infrastructure details (Riverpod, IO) must not leak into the Domain.
2.  **Immutable State**: All `DeviceTree` mutations must follow the **Copy-on-Write** pattern. Direct modification of node properties is prohibited.
3.  **Fail Fast**: Enforce DBC constraints immediately upon input (e.g., `UspPath` parsing). Throw explicit `UspException` for violations.
4.  **Contract over Implementation**: Client-Server communication must rely strictly on the DTOs defined in `usp_protocol_common`.
5.  **Config-Driven Testing**: Integration tests should prioritize using `SmartProvisioner` with real JSON configurations to ensure production parity.

## 8. Governance

* **Versioning**: Follows Semantic Versioning (Major.Minor.Patch).
* **Amendments**: Changes to this Constitution require a documented proposal and approval by the Project Lead.
* **Compliance**: Code reviews must strictly enforce the Architectural Principles defined herein.

---

**Ratified Date:** 2025-11-24
**Status:** Active