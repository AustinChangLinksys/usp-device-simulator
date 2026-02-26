import 'package:test/test.dart';
import 'package:usp_device2_simulator/application/usecases/delete_object_usecase.dart';
import 'package:usp_device2_simulator/domain/entities/device_tree.dart';
import 'package:usp_device2_simulator/domain/repositories/i_device_repository.dart';
import 'package:usp_device2_simulator/infrastructure/commands/command_registry.dart';
import 'package:usp_protocol_common/usp_protocol_common.dart';

class MockDeviceRepository implements IDeviceRepository {
  bool deleteCalled = false;
  UspPath? deletedPath;

  @override
  Future<void> deleteObject(UspPath objectPath) async {
    deleteCalled = true;
    deletedPath = objectPath;
  }

  @override
  Future<UspPath> addObject(
    UspPath parentPath,
    String objectTemplateName, {
    int? instanceId,
  }) async {

    throw UnimplementedError();
  }

  @override
  Future<Map<UspPath, UspValue>> getParameterValue(UspPath path) async {
    throw UnimplementedError();
  }

  

  @override
  Future<void> setParameterValue(UspPath path, UspValue value) async {}

  @override
  DeviceTree getDeviceTree() {
    // Added
    throw UnimplementedError();
  }

  @override
  Future<void> updateInternally(UspPath path, UspValue value) async {
    // Added
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
  group('DeleteObjectUseCase', () {
    test('should call deleteObject on repository', () async {
      // Arrange
      final repository = MockDeviceRepository();
      final useCase = DeleteObjectUseCase(repository);
      final objectPath = UspPath.parse('Device.WiFi.SSID.1');

      // Act
      await useCase.execute(objectPath);

      // Assert
      expect(repository.deleteCalled, isTrue);
      expect(repository.deletedPath, objectPath);
    });
  });
}
