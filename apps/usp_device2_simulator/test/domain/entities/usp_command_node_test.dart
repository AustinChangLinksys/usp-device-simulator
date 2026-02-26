import 'package:test/test.dart';
import 'package:usp_device2_simulator/domain/entities/usp_command_node.dart';
import 'package:usp_protocol_common/usp_protocol_common.dart';

void main() {
  group('UspCommandNode', () {
    test('should instantiate with default values', () {
      final node = UspCommandNode(path: UspPath.parse('Device.Test.'));

      expect(node.isCommand, isTrue);
      expect(node.isParameter, isFalse);
      expect(node.isMultiInstance, isFalse);
      expect(node.isAsync, isFalse);
      expect(node.inputArgs, isEmpty);
      expect(node.outputArgs, isEmpty);
      expect(node.getChild('any'), isNull);
      expect(node.getAllChildren(), isEmpty);
    });

    test('should instantiate with provided values', () {
      final inputArgs = {
        'arg1': UspArgumentDefinition(name: 'arg1', type: UspValueType.string)
      };
      final outputArgs = {
        'out1': UspArgumentDefinition(name: 'out1', type: UspValueType.unsignedInt)
      };
      final node = UspCommandNode(
        path: UspPath.parse('Device.Test.'),
        isAsync: true,
        inputArgs: inputArgs,
        outputArgs: outputArgs,
      );

      expect(node.isAsync, isTrue);
      expect(node.inputArgs, equals(inputArgs));
      expect(node.outputArgs, equals(outputArgs));
    });

    test('copyWith should create a copy with updated values', () {
      final original = UspCommandNode(path: UspPath.parse('Device.Test.'));
      final updated = original.copyWith(isAsync: true);

      expect(updated.path, original.path);
      expect(updated.isAsync, isTrue);
      expect(original.isAsync, isFalse);
    });

    test('copyWith should create a copy with all values updated', () {
      final inputArgs = {
        'arg1': UspArgumentDefinition(name: 'arg1', type: UspValueType.string)
      };
      final outputArgs = {
        'out1': UspArgumentDefinition(name: 'out1', type: UspValueType.unsignedInt)
      };
      final original = UspCommandNode(path: UspPath.parse('Device.Test.'));
      final updated = original.copyWith(
        path: UspPath.parse('Device.NewTest.'),
        isAsync: true,
        inputArgs: inputArgs,
        outputArgs: outputArgs,
      );

      expect(updated.path.fullPath, 'Device.NewTest');
      expect(updated.isAsync, isTrue);
      expect(updated.inputArgs, inputArgs);
      expect(updated.outputArgs, outputArgs);
    });
  });
}