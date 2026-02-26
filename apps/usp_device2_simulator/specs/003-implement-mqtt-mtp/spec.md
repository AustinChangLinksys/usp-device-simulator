# Feature Specification: MQTT MTP Implementation

**Feature Branch**: `003-implement-mqtt-mtp`
**Created**: 2025-11-25
**Status**: Draft
**Input**: User description: "這是一份專為 **SpecKit** 設計的 Prompt，用來生成 **MQTT MTP 實作** 的詳細規格書與任務清單。 這份 Prompt 已經將我們之前的架構決策（使用 `MqttMtpService` 命名、依賴 `usp_protocol_common`、Star Topology 架構）都整合進去了。你可以直接將其貼給 SpecKit。 ----- ### 輸入給 SpecKit 的 Prompt ```markdown # Generate Specification: MQTT MTP Implementation **Context**: We are building `usp_device2_simulator`, a USP (TR-369) Agent. We have successfully implemented the WebSocket MTP server. Now, we need to implement the **MQTT MTP** layer to support standard IoT broker-based communication. **Architecture Reference**: * **Shared Kernel**: `usp_protocol_common` (provides `UspRecordHelper`, `UspProtobufConverter`, DTOs). * **Infrastructure Layer**: The MQTT implementation belongs in `lib/infrastructure/transport/`. * **Adapter Layer**: It must use `UspMessageAdapter` to process requests. **Input Requirements**: Please generate a comprehensive **Feature Specification** and **Implementation Plan** based on the following technical details: --- **Technical Specification: MQTT MTP Service** 1. **Objective**: Implement `MqttMtpService` to allow the Simulator to connect to an external MQTT Broker (e.g., Mosquitto) and exchange USP Records. 2. **Role**: * The Simulator acts as an **MQTT Client** (not a Server). * It connects to a Broker, Subscribes to an Agent Topic, and Publishes to a Controller Topic. 3. **Key Components**: * **Class Name**: `MqttMtpService` * **Location**: `apps/usp_device2_simulator/lib/infrastructure/transport/mqtt_mtp_service.dart` * **Dependencies**: `mqtt_client` (v10.x), `usp_protocol_common`. 4. **Functional Logic**: * **Start**: Connect to Broker -> Subscribe to `agentTopic`. * **Receive**: 1. Listen to `agentTopic`. 2. Extract Payload (Bytes). 3. Use `UspRecordHelper.peekHeader` to get `senderId` (from_id). 4. Use `UspRecordHelper.unwrap` to get `Msg`. 5. Use `UspProtobufConverter` to get DTO. * **Process**: Call `UspMessageAdapter.handleRequest`. * **Reply**: 1. Convert Response DTO -> Msg -> Record. 2. Set Record `to_id` = `senderId`. 3. Determine MQTT Reply Topic (Convention: `usp/controller/{senderId}`). 4. Publish bytes to Reply Topic. 5. **Configuration**: * The `bin/server.dart` entry point needs to be updated to support launching MQTT mode via CLI arguments or default config. 6. **Constraints**: * Must handle connection failures gracefully (try-catch, auto-reconnect logic is optional for v1 but good to have). * Logging must use the standardized format (e.g., `📩 [MQTT] RX...`). --- **Requirements for the Output**: 1. **Spec Structure**: * **User Story**: As a developer, I want the Simulator to connect to an MQTT Broker so that I can test it in a realistic IoT network topology. * **Acceptance Criteria**: 1. Simulator connects to `localhost:1883`. 2. Subscribes to `usp/agent/proto::agent`. 3. Correctly processes a `Get` request sent to that topic. 4. Publishes the `GetResp` back to `usp/controller/{sender_id}`. * **Data Flow Diagram (ASCII)**: Include the Star Topology diagram (Client <-> Broker <-> Agent). 2. **Plan & Tasks**: * **Phase 1: Dependencies & Core Class**: Add `mqtt_client`, create `MqttMtpService` skeleton. * **Phase 2: Connection & Subscription**: Implement `connect()` and `subscribe()`. * **Phase 3: Message Handling Loop**: Implement `_handleMessage` (Unpack -> Adapter -> Pack -> Reply). * **Phase 4: Integration**: Update `bin/server.dart` to initialize MQTT service. * **Phase 5: Verification**: Create `bin/verify_server_mqtt.dart` (a script that acts as a Controller via MQTT) to verify the implementation. ```"

## Clarifications

### Session 2025-11-25
- Q: How should the system handle special characters in the `senderId` for the MQTT reply topic? → A: Replace colons (`:`) in the `senderId` with underscores (`_`).
- Q: What should be the auto-reconnection strategy when the MQTT connection is lost? → A: Attempt to reconnect up to 3 times with a fixed interval (e.g., 5 seconds), then log an error and stop.
- Q: What QoS level should be used for USP Record transmission over MQTT? → A: QoS 1 (At least once).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Connect to MQTT Broker (Priority: P1)

As a developer, I want the Simulator to connect to an MQTT Broker so that I can test it in a realistic IoT network topology.

**Why this priority**: This is the fundamental first step to enable any MQTT-based communication.

**Independent Test**: The connection and subscription can be verified independently by checking the MQTT broker's client list and subscription status.

**Acceptance Scenarios**:

1. **Given** the simulator is configured with MQTT broker details, **When** the simulator starts in MQTT mode, **Then** it successfully connects to the MQTT broker at `localhost:1883`.
2. **Given** the simulator is connected to the MQTT broker, **When** it initializes, **Then** it successfully subscribes to the agent topic `usp/agent/proto::agent`.

---

### User Story 2 - Process USP Messages from MQTT (Priority: P2)

As a developer, I want the simulator to process USP messages received from the MQTT broker and send back responses.

**Why this priority**: This is the core functionality for exchanging USP messages over MQTT.

**Independent Test**: This can be tested by publishing a USP message to the agent topic and verifying that a response is published to the controller topic.

**Acceptance Scenarios**:

1. **Given** the simulator is subscribed to the agent topic, **When** a `Get` request is published to `usp/agent/proto::agent`, **Then** the simulator's `UspMessageAdapter` receives and processes the request.
2. **Given** a `Get` request has been processed, **When** the simulator generates a `GetResp`, **Then** it publishes the response record to the correct controller topic `usp/controller/{sender_id}`.

---

### Edge Cases

- What happens if the MQTT broker is unavailable when the simulator starts?
- How does the system handle a lost connection to the MQTT broker during operation?
- How does the system handle malformed or invalid USP messages received on the agent topic?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST implement an `MqttMtpService` that functions as an MQTT client.
- **FR-002**: The `MqttMtpService` MUST connect to an external MQTT Broker using connection details provided via configuration.
- **FR-003**: The `MqttMtpService` MUST subscribe to a configurable agent topic to receive USP messages.
- **FR-004**: The system MUST listen for incoming messages on the subscribed topic.
- **FR-005**: Upon receiving a message, the system MUST extract the raw byte payload.
- **FR-006**: The system MUST use `UspRecordHelper.peekHeader` to extract the `senderId` from the USP Record header.
- **FR-007**: The system MUST use `UspRecordHelper.unwrap` to get the USP `Msg` from the USP Record.
- **FR-008**: The system MUST use `UspProtobufConverter` to deserialize the `Msg` into a data transfer object (DTO).
- **FR-009**: The resulting DTO MUST be passed to `UspMessageAdapter.handleRequest` for processing.
- **FR-010**: The system MUST serialize the response DTO from the adapter back into a USP Record.
- **FR-011**: The `to_id` field of the response USP Record MUST be set to the `senderId` of the original request.
- **FR-012**: The system MUST publish the serialized response USP Record to the appropriate controller reply topic, following the convention `usp/controller/{senderId}` where any colons (`:`) in the `senderId` are replaced with underscores (`_`).
- **FR-013**: The main `bin/server.dart` entry point MUST be updated to support launching and configuring the `MqttMtpService`.
- **FR-014**: The system MUST gracefully handle connection failures to the MQTT broker by attempting to reconnect up to 3 times with a fixed interval (e.g., 5 seconds). If reconnection fails after 3 attempts, the system MUST log an error and cease further reconnection attempts for the current session.
- **FR-015**: All logging related to MQTT transport MUST follow the standardized format (e.g., `📩 [MQTT] RX...`).
- **FR-016**: All USP Record transmissions over MQTT MUST utilize Quality of Service (QoS) level 1 (At least once) for both publishing and subscribing.
- **SC-004**: The end-to-end MQTT MTP implementation is successfully verified by a dedicated test script (`bin/verify_server_mqtt.dart`) that simulates a USP Controller.
- **SC-005**: The `MqttMtpService` implementation MUST achieve at least 90% unit test coverage.