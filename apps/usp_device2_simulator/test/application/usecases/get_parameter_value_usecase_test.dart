import 'package:test/test.dart';
import 'package:usp_device2_simulator/application/usecases/get_parameter_value_usecase.dart';
import 'package:usp_device2_simulator/domain/entities/device_tree.dart';
import 'package:usp_device2_simulator/domain/repositories/i_device_repository.dart';
import 'package:usp_device2_simulator/infrastructure/commands/command_registry.dart';
import 'package:usp_protocol_common/usp_protocol_common.dart';

class MockDeviceRepository implements IDeviceRepository {
  @override
  Future<Map<UspPath, UspValue>> getParameterValue(UspPath path) async {
    if (path.fullPath == 'Device.Test.Param') {
      return {path: UspValue('test_value', UspValueType.string)};
    }
    return {};
  }

  @override
  Future<void> setParameterValue(UspPath path, UspValue value) async {}

  @override
  Future<UspPath> addObject(
    UspPath parentPath,
    String objectTemplateName, {
    int? instanceId,
  }) async {

    throw UnimplementedError();
  }

  @override
  Future<void> deleteObject(UspPath objectPath) async {
    throw UnimplementedError();
  }

  

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
  group('GetParameterValueUseCase', () {
    test('should return parameter value from repository', () async {
      // Arrange
      final repository = MockDeviceRepository();
      final useCase = GetParameterValueUseCase(repository);
      final path = UspPath.parse('Device.Test.Param');

      // Act
      final result = await useCase.execute(path);

      // Assert
      expect(result.length, 1);
      expect(result.values.first.value, 'test_value');
    });
  });
}
