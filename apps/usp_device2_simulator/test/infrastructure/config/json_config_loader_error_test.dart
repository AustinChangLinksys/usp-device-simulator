import 'dart:io';
import 'package:test/test.dart';
import 'package:usp_device2_simulator/domain/entities/device_tree.dart';
import 'package:usp_device2_simulator/domain/entities/usp_object.dart';
import 'package:usp_device2_simulator/domain/entities/usp_parameter.dart';
import 'package:usp_protocol_common/usp_protocol_common.dart';
import 'package:usp_device2_simulator/infrastructure/config/json_config_loader.dart';

import 'dart:convert'; // Import for jsonEncode

void main() {
  group('JsonConfigLoader Error Handling', () {
    late JsonConfigLoader loader;
    late DeviceTree initialTree;

    setUp(() {
      loader = JsonConfigLoader();
      Directory('.tmp').createSync(recursive: true);
      initialTree = DeviceTree(
        root: UspObject(
          path: UspPath.parse('Device'),
          children: {
            'DeviceInfo': UspObject(
              path: UspPath.parse('Device.DeviceInfo'),
              children: {
                'Manufacturer': UspParameter<String>(
                  path: UspPath.parse('Device.DeviceInfo.Manufacturer'),
                  value: UspValue('DefaultCorp', UspValueType.string),
                  isWritable: true,
                ),
              },
            ),
          },
        ),
      );
    });

    tearDown(() {
      final tmpDir = Directory('.tmp');
      if (tmpDir.existsSync()) {
        tmpDir.deleteSync(recursive: true);
      }
    });

    test('should throw UspException if file not found', () async {
      expect(
        () async =>
            await loader.loadConfig(initialTree, '.tmp/non_existent_file.json'),
        throwsA(
          isA<UspException>().having((e) => e.errorCode, 'errorCode', 7001),
        ),
      );
    });

    test('should throw UspException for type mismatch', () async {
      final jsonConfig = {
        'Device.DeviceInfo.Manufacturer': {'invalid_key': 'invalid_value'},
      }; // Pass a map for a string param
      final configFile = File('.tmp/type_mismatch.json');
      await configFile.writeAsString(jsonEncode(jsonConfig));

      expect(
        () async => await loader.loadConfig(initialTree, configFile.path),
        throwsA(
          isA<UspException>().having((e) => e.errorCode, 'errorCode', 7003),
        ),
      );
    });

    test(
      'should throw UspException for path not found in DeviceTree',
      () async {
        final jsonConfig = {'Device.NonExistent.Path': 'value'};
        final configFile = File('.tmp/path_not_found.json');
        await configFile.writeAsString(jsonEncode(jsonConfig));

        expect(
          () async => await loader.loadConfig(initialTree, configFile.path),
          throwsA(
            isA<UspException>().having((e) => e.errorCode, 'errorCode', 7002),
          ),
        );
      },
    );
  });
}
