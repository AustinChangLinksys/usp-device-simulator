import 'package:test/test.dart';
import 'package:usp_device2_simulator/domain/entities/usp_object.dart';
import 'package:usp_device2_simulator/domain/entities/usp_parameter.dart';
import 'package:usp_protocol_common/usp_protocol_common.dart';

void main() {
  group('UspObject', () {
    test('should be instantiated with correct properties', () {
      final path = UspPath.parse('Device.LocalAgent.');
      final obj = UspObject(
        path: path,
        isMultiInstance: true,
        nextInstanceId: 5,
        minEntries: 1,
        attributes: {'writable': true},
      );

      expect(obj.path, path);
      expect(obj.name, 'LocalAgent');
      expect(obj.isMultiInstance, isTrue);
      expect(obj.nextInstanceId, 5);
      expect(obj.minEntries, 1);
      expect(obj.children, isEmpty);
      expect(obj.attributes, {'writable': true});
    });

    group('copyWith', () {
      late UspObject initialObject;

      setUp(() {
        initialObject = UspObject(
          path: UspPath.parse('Device.LocalAgent.'),
          isMultiInstance: false,
          nextInstanceId: 1,
          minEntries: 0,
          attributes: {'original': 'value'},
        );
      });

      test('should return a new instance with updated attributes', () {
        final updatedObject = initialObject.copyWith(
          attributes: {'new': 'attr'},
        );
        expect(updatedObject.attributes, {'new': 'attr'});
        expect(
          updatedObject.path,
          initialObject.path,
        ); // Unchanged properties remain the same
      });

      test('should return a new instance with updated minEntries', () {
        final updatedObject = initialObject.copyWith(minEntries: 2);
        expect(updatedObject.minEntries, 2);
        expect(
          updatedObject.nextInstanceId,
          initialObject.nextInstanceId,
        ); // Unchanged
      });

      test(
        'should return a new instance with updated path (and derived name)',
        () {
          // Arrange
          final newPath = UspPath.parse('Device.LocalAgent.0.');

          // Act
          final updatedObject = initialObject.copyWith(path: newPath);

          // Assert
          expect(updatedObject.path, newPath);

          // [Fix]: Name should become '0' because it is derived from the path 'Device.LocalAgent.0.'
          expect(updatedObject.name, '0');

          // If you want to verify that it's different from initialObject, you can write it like this:
          expect(updatedObject.name, isNot(initialObject.name));
        },
      );

      test('should return a new instance with updated children', () {
        final newChildren = {
          'Child1': UspObject(path: UspPath.parse('Device.LocalAgent.Child1')),
        };
        final updatedObject = initialObject.copyWith(children: newChildren);
        expect(updatedObject.children, newChildren);
        expect(updatedObject.path, initialObject.path); // Unchanged
      });

      test('should return a new instance with updated isMultiInstance', () {
        final updatedObject = initialObject.copyWith(isMultiInstance: true);
        expect(updatedObject.isMultiInstance, isTrue);
        expect(updatedObject.path, initialObject.path); // Unchanged
      });

      test('should return a new instance with updated nextInstanceId', () {
        final updatedObject = initialObject.copyWith(nextInstanceId: 10);
        expect(updatedObject.nextInstanceId, 10);
        expect(updatedObject.path, initialObject.path); // Unchanged
      });

      test(
        'should return an identical instance if no properties are changed',
        () {
          final updatedObject = initialObject.copyWith();
          expect(updatedObject.path, initialObject.path);
          expect(updatedObject.name, initialObject.name);
          expect(updatedObject.attributes, initialObject.attributes);
          expect(updatedObject.children, initialObject.children);
          expect(updatedObject.isMultiInstance, initialObject.isMultiInstance);
          expect(updatedObject.nextInstanceId, initialObject.nextInstanceId);
          expect(updatedObject.minEntries, initialObject.minEntries);
        },
      );

      test('should correctly report if it is a parameter', () {
        final obj = UspObject(path: UspPath.parse('Device.'));
        expect(obj.isParameter, isFalse);
      });

      test('should return child by name', () {
        final childParam = UspParameter<String>(
          path: UspPath.parse('Device.Test.Param'),
          value: UspValue('value', UspValueType.string),
        );
        final obj = UspObject(
          path: UspPath.parse('Device.Test.'),
          children: {'Param': childParam},
        );
        expect(obj.getChild('Param'), childParam);
        expect(obj.getChild('NonExistent'), isNull);
      });

      test('should return all children', () {
        final child1 = UspObject(path: UspPath.parse('Device.Test.Child1.'));
        final child2 = UspParameter<int>(
          path: UspPath.parse('Device.Test.Param2'),
          value: UspValue(1, UspValueType.int),
        );
        final obj = UspObject(
          path: UspPath.parse('Device.Test.'),
          children: {'Child1': child1, 'Param2': child2},
        );
        expect(obj.getAllChildren(), containsAll([child1, child2]));
        expect(obj.getAllChildren().length, 2);
      });

      test('should correctly report parentPath', () {
        final path = UspPath.parse('Device.Test.Object.');
        final obj = UspObject(path: path);
        expect(obj.parentPath?.fullPath, 'Device.Test');

        final rootPath = UspPath.parse('Device.');
        final rootObj = UspObject(path: rootPath);
        expect(
          rootObj.parentPath?.fullPath,
          '',
        ); // Parent of root is empty path
      });
    });
  });
}
