import 'package:usp_device2_simulator/domain/repositories/i_device_repository.dart';
import 'package:usp_device2_simulator/infrastructure/config/json_config_loader.dart';
import 'package:usp_device2_simulator/infrastructure/repositories/device_repository_impl.dart';
import 'package:usp_device2_simulator/infrastructure/schema/xml_schema_loader.dart';
import 'package:usp_device2_simulator/infrastructure/persistence/i_persistence_service.dart'; // Import the interface
import 'package:usp_device2_simulator/infrastructure/persistence/json_persistence_service.dart'; // Import the implementation
import 'package:usp_device2_simulator/domain/entities/device_tree.dart'; // Import DeviceTree

/// Initializes the USP Device:2 simulator from an XML schema or loads from persistence.
/// Returns an [IDeviceRepository] instance for interacting with the simulated device.
Future<IDeviceRepository> initializeUspDevice2Simulator(String xmlSchemaContent, {String? jsonConfigPath}) async {
  final IPersistenceService persistenceService = JsonPersistenceService(filePath: 'device_tree.json');
  
  // Try to load DeviceTree from persistence
  DeviceTree? deviceTree = await persistenceService.load();

  if (deviceTree == null) {
    // If not found in persistence, load from XML schema
    final schemaLoader = XmlSchemaLoader();
    deviceTree = await schemaLoader.loadSchema(xmlSchemaContent);
    // Save the newly created DeviceTree
    await persistenceService.save(deviceTree);
  }

  // If a JSON config path is provided, load and apply it
  if (jsonConfigPath != null) {
    final configLoader = JsonConfigLoader();
    deviceTree = await configLoader.loadConfig(deviceTree, jsonConfigPath);
    // Save the updated DeviceTree
    await persistenceService.save(deviceTree);
  }

  // Pass the persistence service to the repository so it can save changes
  return DeviceRepositoryImpl(deviceTree, persistenceService);
}