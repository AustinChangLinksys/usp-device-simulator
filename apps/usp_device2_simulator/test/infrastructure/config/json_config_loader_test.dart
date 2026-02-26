import 'dart:io';
import 'dart:convert';
import 'package:test/test.dart';
import 'package:usp_device2_simulator/domain/entities/device_tree.dart';
import 'package:usp_device2_simulator/domain/entities/usp_object.dart';
import 'package:usp_device2_simulator/domain/entities/usp_parameter.dart';
import 'package:usp_protocol_common/usp_protocol_common.dart';
import 'package:usp_device2_simulator/infrastructure/config/json_config_loader.dart';

void main() {
  group('JsonConfigLoader', () {
    late JsonConfigLoader loader;
    late Directory tempDir;

    setUp(() {
      loader = JsonConfigLoader();
      tempDir = Directory.systemTemp.createTempSync('json_config_loader_test');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test(
      'should load config from JSON and override values in DeviceTree',
      () async {
        // 1. Create a simple DeviceTree in memory
        final initialTree = DeviceTree(
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

        // 2. Create a temporary JSON file
        final jsonConfig = {'Device.DeviceInfo.Manufacturer': 'MyCustomCorp'};
        final configFile = File('${tempDir.path}/test_config.json');
        await configFile.writeAsString(jsonEncode(jsonConfig));

        // 3. Run loadConfig
        final updatedTree = await loader.loadConfig(
          initialTree,
          configFile.path,
        );

        // 4. Assert that the values have been updated
        final deviceInfo = updatedTree.root.children['DeviceInfo'] as UspObject;
        final manufacturer =
            deviceInfo.children['Manufacturer'] as UspParameter;
        expect(manufacturer.value.value, 'MyCustomCorp');
      },
    );
    test(
      'should throw UspException if JSON config file not found',
      () async {
        final nonExistentFilePath = '${tempDir.path}/non_existent_config.json';
        final initialTree = DeviceTree(root: UspObject(path: UspPath.parse('Device.')));

        expect(
          () => loader.loadConfig(initialTree, nonExistentFilePath),
          throwsA(
            isA<UspException>().having(
              (e) => e.errorCode,
              'errorCode',
              7001, // Error code for file not found
            ),
          ),
        );
      },
    );
    test('should throw UspException if path not found in DeviceTree', () async {
      final initialTree = DeviceTree(
        root: UspObject(path: UspPath.parse('Device.')),
      ); // A tree without 'Device.NonExistent.Param'

      final jsonConfig = {'Device.NonExistent.Param': 'value'};
      final configFile = File('${tempDir.path}/test_config_non_existent_path.json');
      await configFile.writeAsString(jsonEncode(jsonConfig));

      expect(
        () => loader.loadConfig(initialTree, configFile.path),
        throwsA(
          isA<UspException>().having(
            (e) => e.errorCode,
            'errorCode',
            7002, // Error code for path not found
          ),
        ),
      );
    });
    group('_convertJsonValueToUspValue', () {
      late JsonConfigLoader loader;
      late Directory tempDir;
      late UspObject initialObject;
      late DeviceTree initialTree;

      setUp(() {
        loader = JsonConfigLoader();
        tempDir = Directory.systemTemp.createTempSync('json_config_loader_convert_test');
        initialObject = UspObject(
          path: UspPath.parse('Device.'),
          children: {
            'StringParam': UspParameter<String>(
              path: UspPath.parse('Device.StringParam'),
              value: UspValue('default', UspValueType.string),
              isWritable: true,
            ),
            'IntParam': UspParameter<int>(
              path: UspPath.parse('Device.IntParam'),
              value: UspValue(0, UspValueType.int),
              isWritable: true,
            ),
            'UintParam': UspParameter<int>(
              path: UspPath.parse('Device.UintParam'),
              value: UspValue(0, UspValueType.unsignedInt),
              isWritable: true,
            ),
            'BoolParam': UspParameter<bool>(
              path: UspPath.parse('Device.BoolParam'),
              value: UspValue(false, UspValueType.boolean),
              isWritable: true,
            ),
            'DateTimeParam': UspParameter<String>(
              path: UspPath.parse('Device.DateTimeParam'),
              value: UspValue('', UspValueType.dateTime),
              isWritable: true,
            ),
            'Base64Param': UspParameter<String>(
              path: UspPath.parse('Device.Base64Param'),
              value: UspValue('', UspValueType.base64),
              isWritable: true,
            ),
            'HexBinaryParam': UspParameter<String>(
              path: UspPath.parse('Device.HexBinaryParam'),
              value: UspValue('', UspValueType.hexBinary),
              isWritable: true,
            ),
          },
        );
        initialTree = DeviceTree(root: initialObject);
      });

      tearDown(() {
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      });

      // --- String Conversions ---
      test('should convert string to string', () async {
        final jsonConfig = {'Device.StringParam': 'hello'};
        final configFile = File('${tempDir.path}/test_config_str_str.json');
        await configFile.writeAsString(jsonEncode(jsonConfig));
        final updatedTree = await loader.loadConfig(initialTree, configFile.path);
        final param = (updatedTree.root.children['StringParam'] as UspParameter<String>);
        expect(param.value.value, 'hello');
      });

      test('should convert string to dateTime', () async {
        final jsonConfig = {'Device.DateTimeParam': '2023-01-01T12:00:00Z'};
        final configFile = File('${tempDir.path}/test_config_str_dt.json');
        await configFile.writeAsString(jsonEncode(jsonConfig));
        final updatedTree = await loader.loadConfig(initialTree, configFile.path);
        final param = (updatedTree.root.children['DateTimeParam'] as UspParameter<String>);
        expect(param.value.value, '2023-01-01T12:00:00Z');
      });

      test('should convert string to base64', () async {
        final jsonConfig = {'Device.Base64Param': 'SGVsbG8gV29ybGQ='};
        final configFile = File('${tempDir.path}/test_config_str_b64.json');
        await configFile.writeAsString(jsonEncode(jsonConfig));
        final updatedTree = await loader.loadConfig(initialTree, configFile.path);
        final param = (updatedTree.root.children['Base64Param'] as UspParameter<String>);
        expect(param.value.value, 'SGVsbG8gV29ybGQ=');
      });

      test('should convert string to hexBinary', () async {
        final jsonConfig = {'Device.HexBinaryParam': '0f2a'};
        final configFile = File('${tempDir.path}/test_config_str_hex.json');
        await configFile.writeAsString(jsonEncode(jsonConfig));
        final updatedTree = await loader.loadConfig(initialTree, configFile.path);
        final param = (updatedTree.root.children['HexBinaryParam'] as UspParameter<String>);
        expect(param.value.value, '0f2a');
      });

      test('should convert string to int', () async {
        final jsonConfig = {'Device.IntParam': '123'};
        final configFile = File('${tempDir.path}/test_config_str_int.json');
        await configFile.writeAsString(jsonEncode(jsonConfig));
        final updatedTree = await loader.loadConfig(initialTree, configFile.path);
        final param = (updatedTree.root.children['IntParam'] as UspParameter<int>);
        expect(param.value.value, 123);
      });

      test('should convert string "true" to boolean true', () async {
        final jsonConfig = {'Device.BoolParam': 'true'};
        final configFile = File('${tempDir.path}/test_config_str_bool_t.json');
        await configFile.writeAsString(jsonEncode(jsonConfig));
        final updatedTree = await loader.loadConfig(initialTree, configFile.path);
        final param = (updatedTree.root.children['BoolParam'] as UspParameter<bool>);
        expect(param.value.value, isTrue);
      });

      test('should convert string "false" to boolean false', () async {
        final jsonConfig = {'Device.BoolParam': 'false'};
        final configFile = File('${tempDir.path}/test_config_str_bool_f.json');
        await configFile.writeAsString(jsonEncode(jsonConfig));
        final updatedTree = await loader.loadConfig(initialTree, configFile.path);
        final param = (updatedTree.root.children['BoolParam'] as UspParameter<bool>);
        expect(param.value.value, isFalse);
      });

      test('should throw UspException for invalid boolean string', () async {
        final jsonConfig = {'Device.BoolParam': 'invalid'}; // Use existing BoolParam
        final configFile = File('${tempDir.path}/test_config_invalid_bool_str.json');
        await configFile.writeAsString(jsonEncode(jsonConfig));

        expect(
          () => loader.loadConfig(initialTree, configFile.path),
          throwsA(
            isA<UspException>().having(
              (e) => e.errorCode,
              'errorCode',
              7003, // Invalid boolean string
            ),
          ),
        );
      });

      // --- Int Conversions ---
      test('should convert int to int', () async {
        final jsonConfig = {'Device.IntParam': 456};
        final configFile = File('${tempDir.path}/test_config_int_int.json');
        await configFile.writeAsString(jsonEncode(jsonConfig));
        final updatedTree = await loader.loadConfig(initialTree, configFile.path);
        final param = (updatedTree.root.children['IntParam'] as UspParameter<int>);
        expect(param.value.value, 456);
      });

      test('should convert int to string', () async {
        final jsonConfig = {'Device.StringParam': 789}; // Target type is String, but input is int
        final configFile = File('${tempDir.path}/test_config_int_str.json');
        await configFile.writeAsString(jsonEncode(jsonConfig));
        final updatedTree = await loader.loadConfig(initialTree, configFile.path);
        final param = (updatedTree.root.children['StringParam'] as UspParameter<String>);
        expect(param.value.value, '789');
      });

      // --- Bool Conversions ---
      test('should convert bool to bool', () async {
        final jsonConfig = {'Device.BoolParam': true};
        final configFile = File('${tempDir.path}/test_config_bool_bool.json');
        await configFile.writeAsString(jsonEncode(jsonConfig));
        final updatedTree = await loader.loadConfig(initialTree, configFile.path);
        final param = (updatedTree.root.children['BoolParam'] as UspParameter<bool>);
        expect(param.value.value, isTrue);
      });

      // --- Error cases / Type mismatch ---
      test('should throw UspException for int to datetime type mismatch', () async {
        final jsonConfig = {'Device.DateTimeParam': 123}; // Target is DateTime (String), input is int
        final configFile = File('${tempDir.path}/test_config_int_dt_mismatch.json');
        await configFile.writeAsString(jsonEncode(jsonConfig));

        expect(
          () => loader.loadConfig(initialTree, configFile.path),
          throwsA(
            isA<UspException>().having(
              (e) => e.errorCode,
              'errorCode',
              7003, // Type mismatch
            ),
          ),
        );
      });

      test('should throw UspException for unhandled type mismatch (e.g., bool to int)', () async {
        final jsonConfig = {'Device.IntParam': true}; // Target is int, input is bool
        final configFile = File('${tempDir.path}/test_config_bool_int_mismatch.json');
        await configFile.writeAsString(jsonEncode(jsonConfig));

        expect(
          () => loader.loadConfig(initialTree, configFile.path),
          throwsA(
            isA<UspException>().having(
              (e) => e.errorCode,
              'errorCode',
              7003, // Type mismatch
            ),
          ),
        );
      });
    });
  });
}
