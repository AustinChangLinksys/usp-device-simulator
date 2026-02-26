# Implementation Plan: gRPC Gateway Proxy

**Feature Branch**: `004-grpc-gateway-proxy`  
**Created**: November 25, 2025  
**Status**: Draft  

## 1. Technical Context

This plan outlines the implementation of a gRPC Gateway Proxy within the `usp_device2_simulator` application. This gateway will enable the Simulator to receive USP (User Services Platform) messages via gRPC, tunnel them to its internal Agent logic, and return responses. The plan also includes the development of a client-side verification script to confirm end-to-end connectivity of this gRPC tunnel.

The implementation will be divided into two main phases: Phase 2 (Gateway Server Implementation) and Phase 3 (Verification).

**Phase 2: Gateway Server Implementation (The Proxy Bridge)**
This phase focuses on creating the server-side components required for the gRPC gateway.

1.  **Dependency**: Add the `grpc` package (`grpc: ^3.2.4`) to `apps/usp_device2_simulator/pubspec.yaml`. This provides the necessary gRPC client and server libraries for Dart.
2.  **Service Logic**: Create `lib/infrastructure/transport/grpc_proxy_service.dart`.
    *   This service will implement the `sendUspMessage` method, which is the core logic for handling incoming gRPC USP messages.
    *   The `sendUspMessage` method will perform the following steps:
        *   Validate that the incoming `UspTransportRequest` payload is not empty.
        *   Use `UspRecordHelper.peekHeader` to extract the `senderId` from the USP Record bytes.
        *   Unwrap the `Msg` from the USP Record bytes.
        *   Convert the `Msg` to a Domain Transfer Object (DTO) using `UspProtobufConverter` (if required, based on existing `UspMessageAdapter` implementation details).
        *   Call `UspMessageAdapter.handleRequest` to process the USP message with the internal Agent logic.
        *   Convert the response DTO back to `Msg` (if required).
        *   Wrap the response `Msg` in a new USP Record, setting the recipient to the original `senderId`.
        *   Return this wrapped response as a `UspTransportResponse`.
    *   Error handling will be critical, mapping any internal exceptions (e.g., empty payload, adapter failures) to appropriate `GrpcError` responses.
3.  **Unit Tests**: Create `test/infrastructure/transport/grpc_proxy_service_test.dart`.
    *   The unit tests will cover the core logic of `GrpcProxyService`.
    *   **Constraint**: Must achieve **>90% code coverage** for this service.
    *   Key scenarios to test:
        *   Successful processing of a valid USP message.
        *   Handling of an empty `UspTransportRequest` payload, resulting in an error.
        *   Handling of internal `UspMessageAdapter` failures, ensuring correct `GrpcError` mapping.
4.  **Server Integration**: Update `bin/server.dart`.
    *   The `GrpcProxyService` instance will be initialized.
    *   A gRPC server will be configured to listen on **Port 50051**.
    *   This gRPC server will be started alongside the existing MQTT and WebSocket services, ensuring no port conflicts or operational issues.

**Phase 3: Verification (Client Simulation)**
This phase involves creating a client-side command-line tool to verify the end-to-end functionality of the gRPC gateway.

1.  **Client Script**: Create `bin/verify_server_grpc.dart`.
2.  **Logic**:
    *   Establish a `ClientChannel` connection to `localhost:50051`.
    *   Construct a sample `UspGetRequest` (e.g., requesting the `Device.DeviceInfo.Manufacturer` parameter).
    *   The `UspGetRequest` will be packed into a `UspTransportRequest` for sending over gRPC.
    *   The script will await the `UspTransportResponse`.
    *   Upon receiving the response, it will unpack the payload and verify that the returned value matches an expected string (e.g., "DartSim Networks"), asserting data integrity and successful communication.

## 2. Constitution Check

The plan aligns with the project's constitution, particularly regarding the **Technical Stack & Standards** (Dart, Clean Architecture, Protobuf), **Modularization Strategy** (`usp_protocol_common` for contracts, `usp_device2_simulator` for server logic), and **Guiding Principles** (Domain First, Contract over Implementation, Fail Fast).

*   **Compliance**: The plan leverages the existing `usp_protocol_common` for Protobuf definitions, ensuring compliance with TR-369 (USP).
*   **Architectural Purity**: The `GrpcProxyService` will reside in `lib/infrastructure/transport`, adhering to Clean Architecture by keeping transport details separate from the Domain and Application layers. It will depend on `UspMessageAdapter`, which should act as an entry point to the Application/Domain layer, minimizing leakage of infrastructure concerns.
*   **Robustness**: Error handling (mapping to `GrpcError`) is explicitly called out, supporting the "Fail Fast" principle and robust error reporting.
*   **Automation**: The verification script promotes automated testing of the gRPC tunnel.
*   **Modularization**: The use of `usp_protocol_common` for DTOs and Protobuf-generated code is consistent with the Monorepo strategy.
*   **Testing**: The plan explicitly requires >90% unit test coverage for the new service, in line with quality standards.

## 3. Gates

### Phase 0: Research & Clarification
This feature has a well-defined specification and clear technical requirements, and relies on existing patterns within the project (e.g., `UspMessageAdapter`, `UspRecordHelper`). Therefore, there are no specific items requiring research or clarification (i.e., no `NEEDS CLARIFICATION` markers). The plan can proceed directly to implementation phases.

### Phase 1: Design & Contracts
No specific "design documents" (e.g., data models, API contracts) are required beyond what's already outlined in the feature specification and the `usp_protocol_common` package. The gRPC contract (`usp_transport.proto`) is already defined.

### Phase 2: Gateway Server Implementation
*   **Gate**: Unit tests for `GrpcProxyService` must achieve >90% code coverage.
    *   **Justification**: This is a critical component for USP message tunneling. High test coverage ensures reliability and adherence to requirements.
*   **Gate**: `bin/server.dart` successfully compiles and starts with the gRPC server active on port 50051, alongside other MTP services, without conflicts.
    *   **Justification**: Ensures the server integration is functional and stable.

### Phase 3: Verification
*   **Gate**: `bin/verify_server_grpc.dart` successfully executes and asserts data integrity without errors.
    *   **Justification**: Provides end-to-end validation of the gRPC tunnel.

## 4. Phase 0: Outline & Research

Given the detailed specification and the alignment with existing project patterns and the Constitution, no further research is immediately required. All "NEEDS CLARIFICATION" items from the initial specification phase have been resolved.

## 5. Phase 1: Design & Contracts

### 5.1 Data Model
The core data models (`UspTransportRequest`, `UspTransportResponse`, `UspRecord`, `Msg`) are already defined within `usp_protocol_common` via Protobuf. No new specific data model definitions are required for this feature beyond these existing structures. The interaction will primarily be at the protocol message level.

### 5.2 API Contracts
The API contract for the gRPC service is defined by `usp_transport.proto` within `usp_protocol_common`. The `GrpcProxyService` will implement `UspTransportServiceBase`, which is generated from this proto file. No new API contracts need to be generated.

### 5.3 Quickstart (N/A)
This feature does not introduce a new standalone quickstart. The verification script (`bin/verify_server_grpc.dart`) will serve as a quick integration test example.

### 5.4 Agent Context Update
The `grpc` package is a new dependency that will be added. I will update the agent's context to reflect this.