# USP Device:2 Data Model Engine & Simulator

[](https://dart.dev)
[](https://www.google.com/search?q=https://cleancoder.com/products)
[](https://usp.technology/)

This project provides a high-performance, high-fidelity **TR-181 Device:2 data model engine** and a fully functional **USP Agent Simulator**.

It serves as the core component for building USP-compliant agents and testing controllers. The engine handles complex data structures, path resolution, parameter validation, and state lifecycle management.

Built with **Clean Architecture**, **Domain-Driven Design (DDD)**, and **Design-by-Contract (DBC)** principles.

---

## 🚀 Project Roadmap

| Phase         |   Status    | Description                                                                                                                     |
| :------------ | :---------: | :------------------------------------------------------------------------------------------------------------------------------ |
| **Phase I**   | ✅ **Done** | **Core Foundation & Data Model**<br>Schema-driven engine, Smart Provisioning, Synchronous CRUD, `usp_protocol_common` contract. |
| **Phase II**  | 🔜 **Next** | **Operations & Event Engine**<br>Async `Operate` commands (Reboot, etc.), Active Notification Push, Subscription mechanism.     |
| **Phase III** | 🔒 **Plan** | **Security & RBAC**<br>Endpoint Authorization, Controller Whitelist, Role-Based Access Control.                                 |

---

## 🏗️ Architecture

This project follows a strict separation of concerns, utilizing a **Monorepo** structure with a Shared Kernel.

```text
+-------------------------------------------------------+          +-------------------------------------------------------+
|                 Client (Flutter App)                  |          |               Server (Simulator Agent)                |
|                    [ Controller ]                     |          |                       [ Agent ]                       |
+-------------------------------------------------------+          +-------------------------------------------------------+
|                                                       |          |                                                       |
|  [ Presentation Layer ]                               |          |  [ Infrastructure Layer ]                             |
|   • UI Widgets (Screens)                              |          |   • MTP Server (WebSocket/MQTT/gRPC)                  |
|   • State Management (Riverpod)                       |          |   • File System / Config Loader                       |
|             |                                         |          |             ^                                         |
|             v (Calls)                                 |          |             | (Receives Bytes)                        |
|             v                                         |          |             v                                         |
|  [ Service Layer ]                                    |          |                                                       |
|   • UspClientService                                  |          |  [ Interface Adapter Layer ]                          |
|     (Manages Connection)                              |          |   • UspMessageAdapter                                 |
|             |                                         |          |     1. Unpack: Record -> Msg -> DTO                   |
|             v (Uses)                                  |          |     2. Route:  Dispatch to Repository                 |
|                                                       |          |     3. Pack:   Result -> DTO -> Msg -> Record         |
|  [ Shared Kernel Integration ]                        |          |             |                                         |
|   • DTOs (UspGetRequest...)                           |          |             v (Calls Interface)                       |
|   • Converter (DTO <-> Proto)                         |          |                                                       |
|   • RecordHelper (Msg <-> Record)                     |          |  [ Domain Layer ] (The Brain)                         |
|             |                                         |          |   • IDeviceRepository (Interface)                     |
|             v (Serializes)                            |          |   • DeviceTree (Aggregate Root)                       |
|                                                       |          |   • UspObject / UspParameter (Entities)               |
|  [ Transport Layer ]                                  |          |     (Business Logic: Validation, Permissions)         |
|   • WebSocket / MQTT / gRPC Client                    |          |                                                       |
+-------------+-----------------------------------------+          +-------------------------------------------------------+
              |
              |  Network Transmission (MTP)
              |  Format: USP Record (Protobuf Binary)
              |
              v
      =========================================
      ||        INTERNET / LOCALHOST         ||
      =========================================
```

### Key Components

- **`usp_protocol_common` (Shared Kernel)**:
  A pure Dart library defining the **Communication Contract**. It contains Protobuf definitions, DTOs, Value Objects (`UspPath`, `UspValue`), and stateless converters. It ensures the Client and Server speak the same language.

- **`usp_device2_simulator` (Server Agent)**:

  - **Domain Layer**: The brain. Manages the `DeviceTree` state, enforces schema rules (ReadOnly/ReadWrite), and handles object lifecycle.
  - **Infrastructure Layer**: The body. Handles XML Schema parsing, JSON Config loading, and MTP (WebSocket/MQTT/gRPC) communication.

---

## ✨ Features

- **Schema-Driven Model**: Dynamically constructs the data model from standard TR-181 XML (`tr-181-2-20-0-usp-full.xml`). No hardcoding required.
- **Smart Provisioning**: Automatically analyzes JSON configuration files to instantiate multi-instance objects (e.g., creates `WiFi.Radio.1` if config has `Radio.1.Channel`).
- **Advanced Path Resolution**: Supports wildcards (`*`) for powerful batch queries (e.g., `Device.WiFi.Radio.*.Status`).
- **Full CRUD Support**: Implements `Get`, `Set`, `Add`, `Delete` operations with strict DBC validation.
- **MTP Support**: Built-in **WebSocket, MQTT, and gRPC Servers** for direct control and broker-based communication.
- **Robust Error Handling**: Standardized USP error codes (7002 Path Not Found, 7003 Invalid Arguments, etc.).

---

## 🛠️ Getting Started

### Prerequisites

- Dart SDK (version \>= 3.0)
- `protoc` compiler (if you need to regenerate protocol buffers)

### Installation

Add dependencies to your `pubspec.yaml`:

```yaml
dependencies:
  usp_protocol_common:
    path: ../packages/usp_protocol_common
  xml: ^6.1.0
  json_serializable: ^6.8.0
  grpc: ^3.2.4
  # ... other dependencies
```

---

## 📖 Usage

### 1\. Running as a Standalone Server

The `bin/server.dart` executable allows you to run the simulator as a standalone agent, exposing various MTP (Message Transfer Protocol) services.

```bash
# Run with default WebSocket MTP (port 8080)
dart run bin/server.dart

# Run with MQTT MTP (broker: localhost:1883)
# Ensure an MQTT broker (e.g., Mosquitto) is running
dart run bin/server.dart --mtp mqtt

# Run with gRPC MTP (port 50051)
dart run bin/server.dart --mtp grpc

# Run all MTPs concurrently
dart run bin/server.dart --mtp all

# Customize schema and config paths
dart run bin/server.dart --schema my_schema.xml --config my_config.json
```

### 2\. Using as a Library (Programmatic Access)

You can embed the engine into your own Dart application.

```dart
import 'dart:io';
import 'package:usp_device2_simulator/usp_device2_simulator.dart';
import 'package:usp_protocol_common/usp_protocol_common.dart';
import 'package:usp_device2_simulator/infrastructure/schema/xml_schema_loader.dart';
import 'package:usp_device2_simulator/infrastructure/repositories/device_repository_impl.dart';
import 'package:usp_device2_simulator/infrastructure/persistence/i_persistence_service.dart';

/// Temporary In-Memory Persistence Implementation for example
class InMemoryPersistence implements IPersistenceService {
  @override
  Future<DeviceTree?> load() async => null;
  @override
  Future<void> save(DeviceTree t) async {}
}

Future<void> main() async {
  // 1. Initialize Repository from XML
  final String xmlContent = await File('schema.xml').readAsString();
  final schemaLoader = XmlSchemaLoader();
  final deviceTree = await schemaLoader.loadSchema(xmlContent);

  final repo = DeviceRepositoryImpl(deviceTree, InMemoryPersistence());

  // 2. Interact via Repository Interface
  final path = UspPath.parse('Device.DeviceInfo.Manufacturer');
  final result = await repo.getParameterValue(path);

  print('Manufacturer: ${result.values.first.value}');
}
```

### 3\. Verifying Connectivity

Use the included verification tools to test the running simulator:

```bash
# Verify WebSocket MTP (default)
dart run bin/verify_transport_ws.dart

# Verify MQTT MTP
dart run bin/verify_transport_mqtt.dart

# Verify gRPC MTP
dart run bin/verify_transport_grpc.dart
```

---

## 📚 API Examples

The `IDeviceRepository` is the main entry point for domain operations.

### Get Parameter

```dart
final path = UspPath.parse('Device.WiFi.Radio.*.Status');
final results = await repository.getParameterValue(path);

results.forEach((path, val) {
  print('${path.fullPath} = ${val.value}');
});
```

### Set Parameter

```dart
final path = UspPath.parse('Device.Time.Enable');
final newValue = UspValue(true, UspValueType.boolean);

try {
  await repository.setParameterValue(path, newValue);
  print('Success!');
} on UspException catch (e) {
  print('Failed: ${e.errorMessage} (Code: ${e.errorCode})');
}
```

### Add Object

```dart
final parentPath = UspPath.parse('Device.WiFi.SSID'); // Table Object
try {
  final newPath = await repository.addObject(parentPath, "Ignored");
  print('Created: ${newPath.fullPath}');
} catch (e) {
  print('Error adding object: $e');
}
```

---

## 📂 Directory Structure

- **`/`**: The Server application (Root of this repository).
  - `bin/`: Entry points (`server.dart`, `verify.dart`, `verify_transport_grpc.dart`, `verify_transport_mqtt.dart`, `verify_transport_ws.dart`).
  - `lib/domain/`: Core logic (`DeviceTree`, `Entities`).
  - `lib/infrastructure/`: Implementation (`Repositories`, `SchemaLoader`, `MTP`).
- **`usp_protocol_common/`**: The Shared Kernel (a separate package/repository).
  - `protos/`: USP Protobuf definitions.
  - `lib/src/dtos/`: Request/Response objects.
  - `lib/src/converter/`: Proto <-> DTO conversion logic.

---

## 🤝 Contributing

Contributions are welcome\! Please ensure you run tests before submitting a PR.

```bash
# Run all tests
dart test
```
