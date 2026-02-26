# Tasks for Feature: gRPC Gateway Proxy

**Feature Branch**: `004-grpc-gateway-proxy`
**Created**: November 25, 2025

## Implementation Strategy

This feature will be implemented in a phased approach, prioritizing core functionality and verification. The initial focus will be on setting up necessary dependencies, followed by the implementation of the gRPC Gateway Proxy service and its unit tests. Finally, a client-side verification script will be developed to ensure end-to-end connectivity. This iterative approach allows for early validation of critical components.

### Phase 1: Setup

- [x] T001 Add `grpc: ^3.2.4` dependency to `pubspec.yaml`

### Phase 2: User Story 1 - gRPC USP Message Tunneling (P1)

**Goal**: Enable the Simulator to receive gRPC calls and bridge them to the internal USP Logic.
**Independent Test Criteria**: A mock client can send a USP message via gRPC to the `GrpcProxyService` and receive an appropriate response or error, confirming the service's internal logic and error handling.
**Parallel Execution Example**: Multiple aspects of the `GrpcProxyService` logic (e.g., payload validation, message processing, error handling) can be implemented and tested concurrently by different developers or in isolated environments.

- [x] T002 [US1] Create file `lib/infrastructure/transport/grpc_proxy_service.dart`
- [x] T003 [US1] Implement `GrpcProxyService` class in `lib/infrastructure/transport/grpc_proxy_service.dart`
- [x] T004 [P] [US1] Implement payload validation within `sendUspMessage` in `lib/infrastructure/transport/grpc_proxy_service.dart`
- [x] T005 [P] [US1] Implement `UspRecordHelper.peekHeader` for `senderId` extraction in `sendUspMessage` in `lib/infrastructure/transport/grpc_proxy_service.dart`
- [x] T006 [P] [US1] Implement `Msg` unwrapping from USP Record bytes in `sendUspMessage` in `lib/infrastructure/transport/grpc_proxy_service.dart`
- [x] T007 [P] [US1] Implement conversion of `Msg` to DTO and calling `UspMessageAdapter.handleRequest` in `lib/infrastructure/transport/grpc_proxy_service.dart`
- [x] T008 [P] [US1] Implement conversion of response DTO back to `Msg` and wrapping in USP Record in `sendUspMessage` in `lib/infrastructure/transport/grpc_proxy_service.dart`
- [x] T009 [P] [US1] Implement returning wrapped USP Record as `UspTransportResponse` in `lib/infrastructure/transport/grpc_proxy_service.dart`
- [x] T010 [P] [US1] Implement mapping internal exceptions to `GrpcError` in `sendUspMessage` in `lib/infrastructure/transport/grpc_proxy_service.dart`
- [x] T011 [US1] Create unit test file `test/infrastructure/transport/grpc_proxy_service_test.dart`
- [x] T012 [P] [US1] Implement unit test for successful request scenario in `test/infrastructure/transport/grpc_proxy_service_test.dart`
- [x] T013 [P] [US1] Implement unit test for empty payload error scenario in `test/infrastructure/transport/grpc_proxy_service_test.dart`
- [x] T014 [P] [US1] Implement unit test for adapter failure error scenario in `test/infrastructure/transport/grpc_proxy_service_test.dart`
- [x] T015 [US1] Update `bin/server.dart` to initialize `GrpcProxyService`
- [x] T016 [US1] Update `bin/server.dart` to start gRPC server on port 50051 alongside other MTP services

### Phase 3: User Story 2 - gRPC Client Verification (P1)

**Goal**: Prove the end-to-end flow works using a CLI tool.
**Independent Test Criteria**: Executing the `verify_server_grpc.dart` script successfully connects to the running `GrpcProxyService`, sends a USP GetRequest, receives a valid response, and confirms data integrity.
**Parallel Execution Example**: While the `GrpcProxyService` is being developed, the client verification script can be drafted with mock gRPC responses to accelerate parallel development.

- [x] T017 [US2] Create client script file `bin/verify_server_grpc.dart`
- [x] T018 [P] [US2] Implement `ClientChannel` connection to `localhost:50051` in `bin/verify_server_grpc.dart`
- [x] T019 [P] [US2] Implement construction of `UspGetRequest` (e.g., for `Device.DeviceInfo.Manufacturer`) in `bin/verify_server_grpc.dart`
- [x] T020 [P] [US2] Implement packing `UspGetRequest` into `UspTransportRequest` in `bin/verify_server_grpc.dart`
- [x] T021 [P] [US2] Implement calling `stub.sendUspMessage` in `bin/verify_server_grpc.dart`
- [x] T022 [P] [US2] Implement unpacking response and verifying value matches "DartSim Networks" in `bin/verify_server_grpc.dart`

### Final Phase: Polish & Cross-Cutting Concerns

- [x] T023 Ensure >90% code coverage for `GrpcProxyService` (`test/infrastructure/transport/grpc_proxy_service_test.dart`)
- [x] T024 Verify `bin/server.dart` successfully starts and operates with gRPC, MQTT, and WebSocket services concurrently.
- [x] T025 Run `dart test` to execute all unit and integration tests.
- [x] T026 Manually run `dart run bin/verify_server_grpc.dart` to confirm end-to-end gRPC tunnel functionality.

## Dependencies

- Phase 1 (Setup) must be completed before Phase 2 (User Story 1).
- Phase 2 (User Story 1) must be substantially complete before Phase 3 (User Story 2) for integration testing.

## Parallel Execution Opportunities

- Tasks T004-T010 (implementing individual parts of `sendUspMessage` logic) can be worked on in parallel.
- Tasks T012-T014 (implementing individual unit tests) can be worked on in parallel once the basic service structure is in place.
- Tasks T018-T022 (implementing individual parts of the client verification script) can be worked on in parallel.

## Suggested MVP Scope

The Minimum Viable Product (MVP) for this feature includes completing Phase 1 (Setup) and Phase 2 (User Story 1) and ensuring all associated unit tests pass. This establishes the core gRPC Gateway Proxy functionality. Phase 3 (User Story 2) serves as a critical verification step for the MVP, proving end-to-end connectivity.
