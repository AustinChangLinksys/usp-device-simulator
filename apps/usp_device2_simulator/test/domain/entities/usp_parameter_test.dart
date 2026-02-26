import 'package:test/test.dart';
import 'package:usp_device2_simulator/domain/entities/usp_parameter.dart';
import 'package:usp_protocol_common/usp_protocol_common.dart'; // Import UspException

void main() {
  group('UspParameter', () {
    test('should be instantiated with correct properties', () {
      final path = UspPath.parse('Device.Test.Param');
      final value = UspValue('test_value', UspValueType.string);
      final param = UspParameter<String>(
        path: path,
        value: value,
        isWritable: true,
        attributes: {'access': 'readWrite'},
      );

      expect(param.path, path);
      expect(param.name, 'Param');
      expect(param.value, value);
      expect(param.isWritable, isTrue);
      expect(param.attributes, {'access': 'readWrite'});
    });

    test('isWritable should be false if not explicitly set to true', () {
      final path = UspPath.parse('Device.Test.ReadOnlyParam');
      final value = UspValue(123, UspValueType.int);
      final param = UspParameter<int>(
        path: path,
        value: value,
        isWritable: false,
      );

      expect(param.isWritable, isFalse);
    });

    test('copyWith should create a new instance with updated properties', () {
      final path = UspPath.parse('Device.Test.Param');
      final initialValue = UspValue('initial', UspValueType.string);
      final param = UspParameter<String>(
        path: path,
        value: initialValue,
        isWritable: true,
      );

      final newValue = UspValue('updated', UspValueType.string);
      final updatedParam = param.copyWith(value: newValue);

      expect(updatedParam, isA<UspParameter>());
      expect(updatedParam.path, param.path);
      expect(updatedParam.name, param.name);
      expect(updatedParam.value, newValue); // Value should be updated
      expect(updatedParam.isWritable, param.isWritable);
      expect(updatedParam.attributes, param.attributes);
      expect(updatedParam, isNot(same(param))); // Should be a new instance
    });

    test('validate should throw UspException if parameter is not writable', () {
      final path = UspPath.parse('Device.Test.ReadOnlyParam');
      final value = UspValue(123, UspValueType.int);
      final param = UspParameter<int>(
        path: path,
        value: value,
        isWritable: false,
      );

      final newValue = UspValue(456, UspValueType.int);
      expect(() => param.validate(newValue), throwsA(isA<UspException>()));
    });

    test('validate should not throw if parameter is writable', () {
      final path = UspPath.parse('Device.Test.WritableParam');
      final value = UspValue('old', UspValueType.string);
      final param = UspParameter<String>(
        path: path,
        value: value,
        isWritable: true,
      );

      final newValue = UspValue('new', UspValueType.string);
      expect(() => param.validate(newValue), returnsNormally);
    });

    test('should correctly report multi-instance and parameter status', () {
      final param = UspParameter<String>(
        path: UspPath.parse('Device.Test.Param'),
        value: UspValue('test_value', UspValueType.string),
      );
      expect(param.isMultiInstance, isFalse);
      expect(param.isParameter, isTrue);
    });

    test('should correctly report parentPath', () {
      final path = UspPath.parse('Device.Test.Param');
      final param = UspParameter<String>(
        path: path,
        value: UspValue('test_value', UspValueType.string),
      );
      expect(param.parentPath?.fullPath, 'Device.Test');

      final rootPath = UspPath.parse('Device.');
      final rootParam = UspParameter<String>(
        path: rootPath,
        value: UspValue('test_value', UspValueType.string),
      );
      expect(rootParam.parentPath?.fullPath, ''); // UspPath.root is empty
    });
  });
}
