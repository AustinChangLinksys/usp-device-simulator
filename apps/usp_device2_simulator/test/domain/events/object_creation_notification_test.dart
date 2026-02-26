import 'package:test/test.dart';
import 'package:usp_device2_simulator/domain/entities/device_tree.dart';
import 'package:usp_device2_simulator/domain/entities/usp_object.dart';
import 'package:usp_device2_simulator/domain/events/notifications.dart';
import 'package:usp_protocol_common/usp_protocol_common.dart';
import 'package:usp_device2_simulator/infrastructure/repositories/device_repository_impl.dart';
import 'package:usp_device2_simulator/infrastructure/persistence/i_persistence_service.dart';

// Mock Persistence
class MockPersistenceService implements IPersistenceService {
  @override
  Future<DeviceTree> load() async {
    throw UnimplementedError();
  }

  @override
  Future<void> save(DeviceTree deviceTree) async {}
}

void main() {
  late DeviceRepositoryImpl repository;

  setUp(() {
    // 1. Manually build a tree structure containing a Template
    // Structure: Device -> Services(Table) -> {i}(Template)

    // Define Template {i}
    final templateNode = UspObject(
      path: UspPath.parse('Device.Services.{i}'),
      isMultiInstance: true,
      children: {},
    );

    // Define Table Object (Services)
    final serviceTable = UspObject(
      path: UspPath.parse('Device.Services'),
      children: {'{i}': templateNode}, // <--- Crucial: Must contain {i}
    );

    // Define Root
    final root = UspObject(
      path: UspPath.parse('Device'),
      children: {'Services': serviceTable},
    );

    // Initialize Repository
    final deviceTree = DeviceTree(root: root);
    repository = DeviceRepositoryImpl(deviceTree, MockPersistenceService());
  });

  test('should emit ObjectCreationNotification when object is added', () async {
    // Arrange
    // We want to AddObject to "Device.Services" (Table)
    final parentPath = UspPath.parse('Device.Services');
    final objectTemplateName =
        'Service'; // This name is usually for semantics, the actual logic copies the name of {i}

    // Listen for notifications
    final notifications = <Notification>[];
    final subscription = repository.notifications.listen(notifications.add);

    // Act: Trigger object creation
    // This will create Device.Services.1 (assuming ID is generated as 1)
    // We pass instanceId to ensure predictable test results
    final newObjectPath = await repository.addObject(
      parentPath,
      objectTemplateName,
      instanceId: 1,
    );

    // Allow some time for the stream event to propagate
    await Future.delayed(Duration(milliseconds: 10));

    // Assert
    expect(notifications.length, 1);
    final notification = notifications.first as ObjectCreationNotification;

    // Validate if the notification path is correct (should be the path of the newly created instance)
    expect(notification.path.fullPath, 'Device.Services.1');
    expect(newObjectPath.fullPath, 'Device.Services.1');

    await subscription.cancel();
  });
}
