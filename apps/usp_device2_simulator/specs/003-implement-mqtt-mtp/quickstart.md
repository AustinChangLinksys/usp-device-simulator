# Quickstart Guide: MQTT MTP Implementation

**Date**: 2025-11-25
**Status**: Completed

This guide explains how to run the USP Device:2 Simulator with the MQTT MTP service and how to verify its functionality.

## Prerequisites

1.  A running MQTT Broker (e.g., Mosquitto) accessible at `localhost:1883`.
2.  The `mqtt_client` dependency added to `pubspec.yaml`.

## Running the Simulator in MQTT Mode

The `bin/server.dart` entry point will be updated to support an `--mtp` argument to select the desired MTP service.

To run the server with the MQTT MTP service, execute the following command from the project root:

```bash
dart run bin/server.dart --mtp mqtt
```

The server will start and attempt to connect to the MQTT broker. Upon successful connection, it will subscribe to the agent topic (`usp/agent/proto::agent`) and begin listening for incoming USP requests.

## Verifying the Implementation

A dedicated verification script, `bin/verify_server_mqtt.dart`, will be created to act as a simple USP Controller. This script will:
1. Connect to the MQTT broker.
2. Publish a `Get` request for `Device.DeviceInfo.Manufacturer` to the agent topic.
3. Subscribe to the controller topic to listen for the response.
4. Receive the `GetResp` and verify that the correct manufacturer name is returned.

To run the verification script, execute the following command in a separate terminal:

```bash
dart run bin/verify_server_mqtt.dart
```

If the implementation is correct, the script will print a success message indicating that the `Get` request was processed correctly and a valid `GetResp` was received.
