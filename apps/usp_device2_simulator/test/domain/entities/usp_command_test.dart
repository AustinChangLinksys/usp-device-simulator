import 'package:test/test.dart';
import 'package:usp_device2_simulator/domain/entities/usp_command.dart';
import 'package:usp_protocol_common/usp_protocol_common.dart';

void main() {
  group('UspCommand', () {
    test('should be instantiated with correct properties', () {
      final path = UspPath.parse('Device.LocalAgent.Reboot()');
      final command = UspCommand(path: path, attributes: {'vendor': 'Acme'});

      expect(command.path, path);
      expect(command.name, 'Reboot()');
      expect(command.attributes, {'vendor': 'Acme'});
      expect(command.children, isEmpty);
      expect(command.isMultiInstance, isFalse);
      expect(command.isParameter, isFalse);
      expect(command.isCommand, isTrue);
    });

    test('should return null for getChild and empty for getAllChildren', () {
      final path = UspPath.parse('Device.LocalAgent.Reboot()');
      final command = UspCommand(path: path);

      expect(command.getChild('any'), isNull);
      expect(command.getAllChildren(), isEmpty);
    });

    test('copyWith should create a new instance with updated properties', () {
      final path = UspPath.parse('Device.LocalAgent.Reboot()');
      final initialCommand = UspCommand(
        path: path,
        attributes: {'original': 'value'},
      );

      final updatedCommand = initialCommand.copyWith(
        attributes: {'new': 'attr'},
      );

      expect(updatedCommand, isA<UspCommand>());
      expect(updatedCommand.path, initialCommand.path);
      expect(updatedCommand.name, initialCommand.name);
      expect(updatedCommand.attributes, {'new': 'attr'});
      expect(
        updatedCommand,
        isNot(same(initialCommand)),
      ); // Should be a new instance
    });

    test('execute should return a success status', () async {
      final path = UspPath.parse('Device.LocalAgent.Reboot()');
      final command = UspCommand(path: path);

      final result = await command.execute({'param1': 'value1'});

      expect(result, {'status': 'Success'});
    });

    test('toJson should correctly serialize the UspCommand object', () {
      final path = UspPath.parse('Device.LocalAgent.Reboot()');
      final command = UspCommand(
        path: path,
        attributes: {'vendor': 'Acme', 'version': '1.0'},
      );

      final json = command.toJson();

      expect(json['path']['segments'], ['Device', 'LocalAgent', 'Reboot()']);
      expect(json['attributes'], {'vendor': 'Acme', 'version': '1.0'});
    });

    test('fromJson should correctly deserialize the UspCommand object', () {
      final json = {
        'path': {
          'segments': ['Device', 'LocalAgent', 'Reboot()'],
          'hasWildcard': false,
          'aliasFilter': {},
        },

        'attributes': {'vendor': 'Acme', 'version': '1.0'},
      };

      final command = UspCommand.fromJson(json);

      expect(command.path.fullPath, 'Device.LocalAgent.Reboot()');
      expect(command.attributes, {'vendor': 'Acme', 'version': '1.0'});
      expect(command.isMultiInstance, false);
      expect(command.isParameter, false);
    });

    test('should correctly report parentPath', () {
      final path = UspPath.parse('Device.Test.Command()');
      final command = UspCommand(path: path);
      expect(command.parentPath?.fullPath, 'Device.Test');

      final rootPath = UspPath.parse('Device.');
      final rootCommand = UspCommand(path: rootPath);
      expect(rootCommand.parentPath?.fullPath, ''); // UspPath.root is empty
    });
  });
}
