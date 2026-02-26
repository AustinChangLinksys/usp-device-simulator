import 'package:usp_device2_simulator/domain/entities/device_tree.dart';
import 'package:usp_device2_simulator/infrastructure/commands/command_registry.dart';
import 'package:usp_protocol_common/usp_protocol_common.dart';

abstract class IDeviceRepository {
  Future<Map<UspPath, UspValue>> getParameterValue(UspPath path);
  Future<void> setParameterValue(UspPath path, UspValue value);
  Future<UspPath> addObject(UspPath parentPath, String objectTemplateName, {int? instanceId});
  Future<void> deleteObject(UspPath objectPath);
  Future<UspSupportedDMObject> getSupportedDM(UspPath path);
  Future<Map<String, UspValue>> operate(UspPath commandPath, Map<String, UspValue> inputArgs);
  Future<List<UspInstanceResult>> getInstances(UspPath path, bool firstLevelOnly);
  DeviceTree getDeviceTree(); // Getter for the DeviceTree
  Future<void> updateInternally(UspPath path, UspValue value); // For internal system use
  Future<void> updateTree(DeviceTree newTree);

  Future<void> injectCommandImplementations(CommandRegistry registry);
}
