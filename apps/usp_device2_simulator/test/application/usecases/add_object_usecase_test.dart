import 'package:test/test.dart';
import 'package:usp_device2_simulator/application/usecases/add_object_usecase.dart';
import 'package:usp_device2_simulator/domain/entities/device_tree.dart';
import 'package:usp_device2_simulator/domain/repositories/i_device_repository.dart';
import 'package:usp_device2_simulator/infrastructure/commands/command_registry.dart';
import 'package:usp_protocol_common/usp_protocol_common.dart';

class MockDeviceRepository implements IDeviceRepository {
  @override
  Future<UspPath> addObject(UspPath parentPath, String objectTemplateName, {int? instanceId}) async { // Added instanceId
    // Simulate adding an object and returning its path
    final newInstanceId = instanceId ?? 1; // Use provided instanceId or default to 1
    return UspPath.parse('${parentPath.fullPath}.$objectTemplateName.$newInstanceId');
  }

  @override
  Future<void> deleteObject(UspPath objectPath) async {}

  @override
  Future<Map<UspPath, UspValue>> getParameterValue(UspPath path) async {
    throw UnimplementedError();
  }

  @override
  Future<void> setParameterValue(UspPath path, UspValue value) async {}

  @override
  DeviceTree getDeviceTree() { // Added
    throw UnimplementedError();
  }

  @override
  Future<void> updateInternally(UspPath path, UspValue value) async { // Added
    throw UnimplementedError();
  }
  
  @override
  Future<void> updateTree(DeviceTree newTree) {
    throw UnimplementedError();
  }
  
  @override
  Future<UspSupportedDMObject> getSupportedDM(UspPath path) {
    throw UnimplementedError();
  }

  @override
  Future<List<UspInstanceResult>> getInstances(UspPath path, bool firstLevelOnly) {
    throw UnimplementedError();
  }

  @override
  Future<void> injectCommandImplementations(CommandRegistry registry) {
    throw UnimplementedError();
  }
  
  @override
  Future<Map<String, UspValue>> operate(UspPath commandPath, Map<String, UspValue> inputArgs) {
    throw UnimplementedError();
  }
}

void main() {
  group('AddObjectUseCase', () {
    test('should call addObject on repository and return new object path', () async {
      // Arrange
      final repository = MockDeviceRepository();
      final useCase = AddObjectUseCase(repository);
      final parentPath = UspPath.parse('Device.WiFi.');
      final objectTemplateName = 'SSID';

      // Act
      final newPath = await useCase.execute(parentPath, objectTemplateName, instanceId: 1); // Pass instanceId

      // Assert
      expect(newPath.fullPath, 'Device.WiFi.SSID.1');
    });
  });
}
