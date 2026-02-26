# Feature Specification: gRPC Gateway Proxy

**Feature Branch**: `004-grpc-gateway-proxy`  
**Created**: November 25, 2025  
**Status**: Draft  
**Input**: User description: "**Context**: We have successfully defined the gRPC contract in `usp_protocol_common` (Phase 1). Now we need to implement the **Gateway Proxy** logic within the Simulator (`usp_device2_simulator`) and provide a verification script to test the gRPC tunnel. **Architecture Role**: The Simulator will act as the **Router Gateway**, exposing a gRPC Server (Port 50051) that tunnels USP Records to the internal Agent logic. **Input Specification Reference**: --- **Technical Specification: gRPC Gateway & Client** 1. **Component A: GrpcProxyService (Server-side)** * **Location**: `apps/usp_device2_simulator/lib/infrastructure/transport/grpc_proxy_service.dart` * **Inheritance**: Must extend `UspTransportServiceBase` (from common). * **Dependencies**: `grpc`, `usp_protocol_common`, `UspMessageAdapter`. * **Logic (`sendUspMessage`)**: 1. Receive `UspTransportRequest`. 2. Validate payload is not empty. 3. **Peek Header**: Use `UspRecordHelper` to identify `senderId`. 4. **Unwrap**: Extract `Msg` from Record bytes. 5. **Process**: Convert `Msg` to DTO, call `UspMessageAdapter.handleRequest`. 6. **Reply**: Convert Response DTO to `Msg`, wrap in Record (to: `senderId`), and return as `UspTransportResponse`. * **Error Handling**: Map internal exceptions to `GrpcError`. 2. **Component B: Server Entry Point Update** * **Location**: `apps/usp_device2_simulator/bin/server.dart` * **Task**: Initialize `GrpcProxyService` and start a gRPC Server listening on **Port 50051** alongside existing WebSocket/MQTT services. 3. **Component C: Verification Script (Client-side)** * **Location**: `apps/usp_device2_simulator/bin/verify_server_grpc.dart` * **Logic**: 1. Create a gRPC `ClientChannel` to `localhost:50051`. 2. Construct a `UspGetRequest` (DTO) -> Proto -> Record Bytes. 3. Call `stub.sendUspMessage`. 4. Unwrap response bytes and assert data integrity. --- **Requirements for the Plan**: 1. **Phasing Strategy**: * **Phase 2: Gateway Implementation**: Implement `GrpcProxyService` and update `server.dart`. Includes Unit Tests for the Service logic. * **Phase 3: Verification**: Create the CLI verification tool to prove end-to-end connectivity. 2. **Quality Standards**: * **Test Coverage**: The `GrpcProxyService` logic must have **>90% unit test coverage** (mocking the Adapter). * **Error Handling**: Specifically test scenarios like "Empty Payload" or "Adapter Failure"."

## User Scenarios & Testing

### User Story 1 - gRPC USP Message Tunneling (Priority: P1)

A client sends a USP message via gRPC to the Simulator's gRPC Gateway. The Gateway processes the message, adapts it, and routes it to the internal Agent logic. The Agent's response is then tunneled back to the client via gRPC.

**Why this priority**: This is the core functionality of the feature, enabling communication with the internal Agent logic over gRPC.

**Independent Test**: Can be fully tested by sending a valid USP message to the gRPC Gateway and verifying the correct response from the internal Agent logic.

**Acceptance Scenarios**:

1.  **Given** the gRPC Gateway Proxy is running and listening on Port 50051, **When** a `UspTransportRequest` with a valid USP Record payload is sent to `sendUspMessage`, **Then** the message is successfully processed by the internal Agent logic, and a `UspTransportResponse` containing the Agent's reply is returned.
2.  **Given** the gRPC Gateway Proxy is running and listening on Port 50051, **When** a `UspTransportRequest` with an empty payload is sent to `sendUspMessage`, **Then** the Gateway Proxy returns a `GrpcError` indicating an invalid payload.
3.  **Given** the gRPC Gateway Proxy is running and listening on Port 50051, **When** a `UspTransportRequest` with an invalid USP Record payload (e.g., malformed) is sent to `sendUspMessage`, **Then** the Gateway Proxy returns a `GrpcError` indicating a processing error.

---

### User Story 2 - gRPC Client Verification (Priority: P1)

A dedicated verification script (client-side) can successfully establish a gRPC connection to the Simulator's Gateway Proxy, send a USP message (e.g., a GetRequest), and receive a valid response, confirming end-to-end connectivity.

**Why this priority**: This script is crucial for validating the entire gRPC tunnel implementation and serves as a direct integration test.

**Independent Test**: Running the verification script should produce a successful assertion of data integrity, confirming the gRPC tunnel is operational.

**Acceptance Scenarios**:

1.  **Given** the gRPC Gateway Proxy is running, **When** the `verify_server_grpc.dart` script is executed, **Then** it successfully connects to `localhost:50051`, sends a `UspGetRequest`, receives a `UspTransportResponse`, and asserts the integrity of the returned data without errors.

## Requirements

### Functional Requirements

-   **FR-001**: The system MUST expose a gRPC server on Port 50051 for tunneling USP Records.
-   **FR-002**: The gRPC server MUST implement the `sendUspMessage` method as defined by `UspTransportServiceBase`.
-   **FR-003**: The `sendUspMessage` method MUST validate that the incoming `UspTransportRequest` payload is not empty.
-   **FR-004**: The `sendUspMessage` method MUST extract the `senderId` from the USP Record bytes using `UspRecordHelper`.
-   **FR-005**: The `sendUspMessage` method MUST unwrap the `Msg` from the USP Record bytes.
-   **FR-006**: The `sendUspMessage` method MUST convert the `Msg` to a DTO and call `UspMessageAdapter.handleRequest`.
-   **FR-007**: The `sendUspMessage` method MUST convert the response DTO back to `Msg` and wrap it in a USP Record (addressed to the original `senderId`).
-   **FR-008**: The `sendUspMessage` method MUST return the wrapped USP Record as a `UspTransportResponse`.
-   **FR-009**: The `sendUspMessage` method MUST map internal exceptions to `GrpcError` for proper gRPC error handling.
-   **FR-010**: The main server entry point (`server.dart`) MUST initialize and start the `GrpcProxyService` alongside existing services.
-   **FR-011**: A client-side verification script (`verify_server_grpc.dart`) MUST be provided to test end-to-end gRPC tunnel connectivity.
-   **FR-012**: The verification script MUST create a gRPC `ClientChannel` to `localhost:50051`.
-   **FR-013**: The verification script MUST construct a `UspGetRequest` DTO, convert it to Proto, and then to USP Record Bytes.
-   **FR-014**: The verification script MUST call `stub.sendUspMessage` with the constructed USP Record.
-   **FR-015**: The verification script MUST unwrap the response bytes and assert data integrity.

### Key Entities

-   **UspTransportRequest**: Represents an incoming USP message over gRPC. Contains the USP Record payload.
-   **UspTransportResponse**: Represents an outgoing USP message over gRPC. Contains the USP Record payload.
-   **UspRecord**: The fundamental data structure for USP messages, containing `Msg` and `senderId`/`receiverId` information.
-   **Msg**: The actual USP message content (e.g., Get, Set, Add, Delete, Notify).
-   **UspMessageAdapter**: An existing component responsible for handling the conversion and routing of USP messages to the internal Agent logic.

## Success Criteria

### Measurable Outcomes

-   **SC-001**: The `GrpcProxyService` logic achieves greater than 90% unit test coverage.
-   **SC-002**: The `GrpcProxyService` correctly handles and maps internal exceptions to `GrpcError` for scenarios like empty payloads or adapter failures.
-   **SC-003**: The `verify_server_grpc.dart` script successfully executes, connects to the gRPC Gateway, sends a USP `Get` request, and validates the received response without errors, indicating successful end-to-end tunneling.
-   **SC-004**: The Simulator can successfully start and operate with the gRPC server enabled, alongside existing WebSocket/MQTT services, without conflicts.