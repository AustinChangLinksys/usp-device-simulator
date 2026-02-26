import 'package:test/test.dart';
import 'package:usp_device2_simulator/domain/entities/device_tree.dart';
import 'package:usp_device2_simulator/domain/entities/usp_object.dart';
import 'package:usp_device2_simulator/domain/entities/usp_parameter.dart';
import 'package:usp_protocol_common/usp_protocol_common.dart';

void main() {
  group('DeviceTree', () {
    late UspObject root;
    late DeviceTree deviceTree;

    setUp(() {
      root = UspObject(
        path: UspPath.parse('Device.'),
        children: {
          'DeviceInfo': UspObject(
            path: UspPath.parse('Device.DeviceInfo.'),
            children: {
              'Manufacturer': UspParameter<String>(
                path: UspPath.parse('Device.DeviceInfo.Manufacturer'),
                value: UspValue('DefaultCorp', UspValueType.string),
              ),
              'SerialNumber': UspParameter<String>(
                path: UspPath.parse('Device.DeviceInfo.SerialNumber'),
                value: UspValue('12345', UspValueType.string),
              ),
            },
          ),
          'Hosts': UspObject(
            path: UspPath.parse('Device.Hosts.'),
            isMultiInstance: true,
            children: {
              '{i}': UspObject(
                // Template for multi-instance
                path: UspPath.parse('Device.Hosts.{i}.'),
                children: {
                  'HostName': UspParameter<String>(
                    path: UspPath.parse('Device.Hosts.{i}.HostName'),
                    value: UspValue('', UspValueType.string),
                  ),
                },
              ),
              '1': UspObject(
                path: UspPath.parse('Device.Hosts.1.'),
                children: {
                  'HostName': UspParameter<String>(
                    path: UspPath.parse('Device.Hosts.1.HostName'),
                    value: UspValue('Guest1', UspValueType.string),
                  ),
                },
              ),
            },
          ),
        },
      );
      deviceTree = DeviceTree(root: root);
    });

    test(
      'updateNode should not recreate unchanged sibling subtrees (covering _replaceNodeInTree no change)',
      () {
        final initialHosts =
            (deviceTree.root.children['Hosts']
                as UspObject); // Change from LAN to Hosts
        final newDeviceTree = deviceTree.updateNode(
          UspParameter<String>(
            path: UspPath.parse('Device.DeviceInfo.Manufacturer'),
            value: UspValue('UpdatedCorp', UspValueType.string),
          ),
        );

        // Verify that the Hosts branch is the exact same instance, meaning _replaceNodeInTree returned currentObject for it.
        expect(newDeviceTree.root.children['Hosts'], same(initialHosts));
        // Also verify the updated value is correct
        final updatedManufacturer =
            (newDeviceTree.root.children['DeviceInfo'] as UspObject)
                    .children['Manufacturer']
                as UspParameter<String>;
        expect(updatedManufacturer.value.value, 'UpdatedCorp');
      },
    );

    test(
      'updateNode should throw UspException when trying to replace root with non-object',
      () {
        final param = UspParameter<String>(
          path: UspPath.parse('Device.'),
          value: UspValue('test', UspValueType.string),
        );

        expect(
          () => deviceTree.updateNode(param),
          throwsA(
            isA<UspException>().having((e) => e.errorCode, 'errorCode', 7001),
          ),
        );
      },
    );

    test(
      'addObject should throw UspException when parent path does not exist',
      () {
        final nonExistentPath = UspPath.parse('Device.DoesNotExist.');
        final newObject = UspObject(
          path: UspPath.parse('Device.DoesNotExist.NewObject.'),
        );

        expect(
          () => deviceTree.addObject(nonExistentPath, newObject),
          throwsA(
            isA<UspException>().having((e) => e.errorCode, 'errorCode', 7002),
          ),
        );
      },
    );

    test(
      'deleteObject should throw UspException when trying to delete the root',
      () {
        final rootPath = UspPath.parse('Device.');
        expect(
          () => deviceTree.deleteObject(rootPath),
          throwsA(
            isA<UspException>().having((e) => e.errorCode, 'errorCode', 7006),
          ),
        );
      },
    );

    test('deleteObject should throw UspException when object is not found', () {
      final nonExistentPath = UspPath.parse('Device.DoesNotExist.');
      expect(
        () => deviceTree.deleteObject(nonExistentPath),
        throwsA(
          isA<UspException>().having((e) => e.errorCode, 'errorCode', 7002),
        ),
      );
    });

    test(
      'deleteObject should not recreate unchanged sibling subtrees (covering _removeNodeInTree no change)',
      () {
        final initialDeviceInfo = deviceTree.root.children['DeviceInfo']!;
        final newObject = UspObject(
          path: UspPath.parse('Device.Hosts.NewObject'),
          children: {},
        );
        // Add a new object to Hosts branch, then delete it.
        // This will ensure that when we delete, DeviceInfo subtree is not touched.
        DeviceTree treeWithNewObject = deviceTree.addObject(
          UspPath.parse('Device.Hosts.'),
          newObject,
        );

        final newDeviceTree = treeWithNewObject.deleteObject(newObject.path);

        // Verify that the DeviceInfo branch is the exact same instance
        expect(
          newDeviceTree.root.children['DeviceInfo'],
          same(initialDeviceInfo),
        );
      },
    );
    test(
      'deleteObject removes specific instance from multi-instance object',
      () {
        final host1Path = UspPath.parse('Device.Hosts.1.');
        final initialDeviceInfo = deviceTree.root.children['DeviceInfo']!;

        final newDeviceTree = deviceTree.deleteObject(host1Path);

        // Verify Host1 is removed
        final hosts = newDeviceTree.root.children['Hosts'] as UspObject;
        expect(hosts.children.containsKey('1'), isFalse);

        // Verify template and other static branches are untouched
        expect(hosts.children.containsKey('{i}'), isTrue);
        expect(
          newDeviceTree.root.children['DeviceInfo'],
          same(initialDeviceInfo),
        );
      },
    );
  });
}
