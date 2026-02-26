import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:usp_device2_simulator/domain/entities/device_tree.dart';
import 'package:usp_device2_simulator/domain/entities/usp_object.dart';
import 'package:usp_device2_simulator/domain/events/notifications.dart';
import 'package:usp_protocol_common/usp_protocol_common.dart';
import 'package:usp_device2_simulator/infrastructure/repositories/device_repository_impl.dart';

import '../../mocks.dart';


void main() {
  setUpAll(() {
    registerDeviceTreeFallback(); // Register fallback for DeviceTree
  });

  group('ObjectDeletionNotification', () {
    late DeviceRepositoryImpl repository;
    late DeviceTree deviceTree;
    late UspPath initialObjectPath;
    late MockPersistenceService mockPersistenceService; // Declare mock

    setUp(() async {
      mockPersistenceService = MockPersistenceService(); // Initialize mock
      // Stub the save method to do nothing
      when(() => mockPersistenceService.save(any())).thenAnswer((_) async {});
      when(() => mockPersistenceService.load()).thenAnswer((_) async => null);

      final initialObject = UspObject(
        path: UspPath.parse('Device.Service.1'),
        isMultiInstance: true,
      );
      final serviceObject = UspObject(
        path: UspPath.parse('Device.Service'),
        children: {'1': initialObject},
        isMultiInstance: true,
      );
      final root = UspObject(
        path: UspPath.parse('Device'),
        children: {'Service': serviceObject},
      );
      deviceTree = DeviceTree(root: root);
      repository = DeviceRepositoryImpl(
        deviceTree,
        mockPersistenceService,
      ); // Pass mock
      initialObjectPath = initialObject.path;
    });

    test(
      'should emit ObjectDeletionNotification when object is deleted',
      () async {
        // Listen for notifications
        final notifications = <Notification>[];
        final subscription = repository.notifications.listen(notifications.add);

        // Trigger object deletion
        await repository.deleteObject(initialObjectPath);

        // Allow some time for the event to propagate
        await Future.delayed(Duration(milliseconds: 10));

        // Assert
        expect(notifications.length, 1);
        final notification = notifications.first as ObjectDeletionNotification;
        expect(notification.path, initialObjectPath);

        await subscription.cancel();
      },
    );
  });
}
