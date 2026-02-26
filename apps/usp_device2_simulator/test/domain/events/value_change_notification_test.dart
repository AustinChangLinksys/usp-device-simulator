import 'package:test/test.dart';
import 'package:usp_device2_simulator/domain/entities/device_tree.dart';
import 'package:usp_device2_simulator/domain/entities/usp_object.dart';
import 'package:usp_device2_simulator/domain/entities/usp_parameter.dart';
import 'package:usp_device2_simulator/domain/events/notifications.dart';
import 'package:usp_protocol_common/usp_protocol_common.dart';
import 'package:usp_device2_simulator/infrastructure/repositories/device_repository_impl.dart';
import '../../mocks.dart'; 
import 'package:mocktail/mocktail.dart'; 

void main() {
  setUpAll(() {
    registerDeviceTreeFallback(); 
  });

  group('ValueChangeNotification', () {
    late DeviceRepositoryImpl repository;
    late DeviceTree deviceTree;
    late MockPersistenceService mockPersistenceService; 

    setUp(() {
      mockPersistenceService = MockPersistenceService(); 
      // Stub the save method to do nothing
      when(() => mockPersistenceService.save(any())).thenAnswer((_) async {});
      when(() => mockPersistenceService.load()).thenAnswer((_) async => null);

      final param = UspParameter<String>(
        path: UspPath.parse('Device.Test.Param'),
        value: UspValue('initial', UspValueType.string),
        isWritable: true,
      );
      final testObj = UspObject(
        path: UspPath.parse('Device.Test'),
        children: {'Param': param},
      );
      final root = UspObject(
        path: UspPath.parse('Device'),
        children: {'Test': testObj},
      );
      deviceTree = DeviceTree(root: root);
      repository = DeviceRepositoryImpl(
        deviceTree,
        mockPersistenceService,
      ); // Pass mock
    });

    test(
      'should emit ValueChangeNotification when parameter value changes',
      () async {
        final expectedPath = UspPath.parse('Device.Test.Param');
        final oldValue = UspValue('initial', UspValueType.string);
        final newValue = UspValue('updated', UspValueType.string);

        // Listen for notifications
        final notifications = <Notification>[];
        final subscription = repository.notifications.listen(notifications.add);

        // Trigger value change
        await repository.setParameterValue(expectedPath, newValue);

        // Allow some time for the event to propagate
        await Future.delayed(Duration(milliseconds: 10));

        // Assert
        expect(notifications.length, 1);
        final notification = notifications.first as ValueChangeNotification;
        expect(notification.path, expectedPath);
        expect(notification.oldValue, oldValue);
        expect(notification.newValue, newValue);

        await subscription.cancel();
      },
    );
  });
}
