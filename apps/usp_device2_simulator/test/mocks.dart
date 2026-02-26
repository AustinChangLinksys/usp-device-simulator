import 'dart:io';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:usp_device2_simulator/infrastructure/schema/i_schema_loader.dart';
import 'package:usp_device2_simulator/infrastructure/adapter/usp_message_adapter.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

import 'package:usp_device2_simulator/domain/entities/device_tree.dart';
import 'package:usp_device2_simulator/domain/entities/usp_object.dart'; // Import UspObject
import 'package:usp_protocol_common/usp_protocol_common.dart';
import 'package:usp_device2_simulator/infrastructure/persistence/i_persistence_service.dart';
import 'package:mocktail/mocktail.dart';

class MockPersistenceService extends Mock implements IPersistenceService {}

// Mock SchemaLoader
class MockSchemaLoader extends Mock implements ISchemaLoader {}

// Mock File (from dart:io)
class MockFile extends Mock implements File {}

class MockUspMessageAdapter extends Mock implements UspMessageAdapter {}

class MockMqttServerClient extends Mock implements MqttServerClient {}

class MockSubscription extends Mock implements Subscription {}

// A fake DeviceTree for mocktail to use as a fallback value
class FakeDeviceTree extends Fake implements DeviceTree {
  // Implement any required methods/getters with dummy values if needed by the tests
  // For now, a minimal implementation might be enough
  // A DeviceTree always has a root UspObject
  @override
  final UspObject root;

  FakeDeviceTree() : root = UspObject(path: UspPath.parse('Device'));
}

// Register fallback for DeviceTree in a separate function to be called in setUpAll
void registerDeviceTreeFallback() {
  registerFallbackValue(FakeDeviceTree());
}