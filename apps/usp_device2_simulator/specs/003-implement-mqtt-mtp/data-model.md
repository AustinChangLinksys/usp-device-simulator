# Data Model for MQTT MTP Implementation

**Date**: 2025-11-25
**Status**: Completed

## Summary

No new domain entities are introduced by the MQTT MTP implementation. This feature is a transport-layer service and does not alter the core Device:2 data model.

## Data Entities

The implementation will exclusively handle existing data structures defined in the `usp_protocol_common` shared kernel, primarily:

-   **`UspRecord`**: The protobuf-defined message wrapper for all USP communications.
-   **`UspMsg`**: The protobuf-defined container for specific USP requests and responses (e.g., `Get`, `GetResp`).

These entities are already defined and are used as the contract for communication between the USP Agent and Controllers. The `MqttMtpService` will be responsible for serializing and deserializing these objects for transport over MQTT, but it will not define or own any new data structures within the domain.
