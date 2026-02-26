import 'dart:io';
import 'dart:convert';
import 'package:usp_device2_simulator/domain/entities/device_tree.dart';
import 'package:usp_device2_simulator/domain/entities/usp_node.dart';
import 'package:usp_device2_simulator/domain/entities/usp_parameter.dart';
import 'package:usp_protocol_common/usp_protocol_common.dart';
import 'package:usp_device2_simulator/infrastructure/config/i_config_loader.dart';

class JsonConfigLoader implements IConfigLoader {
  @override
  Future<DeviceTree> loadConfig(
    DeviceTree initialTree,
    String configPath,
  ) async {
    final file = File(configPath);
    if (!await file.exists()) {
      throw UspException(7001, 'JSON config file not found: $configPath');
    }

    final jsonString = await file.readAsString();
    final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;

    DeviceTree currentTree = initialTree;
    final pathResolver = PathResolver();
    final skipped = <String>[];

    for (final entry in jsonMap.entries) {
      final pathStr = entry.key;
      final jsonValue = entry.value;
      final path = UspPath.parse(pathStr);

      final nodes = pathResolver.resolve<UspNode>(currentTree.root, path);

      if (nodes.isEmpty) {
        skipped.add('$pathStr (not in schema)');
        continue;
      }

      for (final node in nodes) {
        if (node is UspParameter) {
          final expectedType = node.value.type;
          UspValue newUspValue;

          try {
            newUspValue = _convertJsonValueToUspValue(jsonValue, expectedType);
          } catch (e) {
            skipped.add('$pathStr (${e is UspException ? e.message : e})');
            continue;
          }

          final newParam = node.copyWith(value: newUspValue);
          currentTree = currentTree.updateNode(newParam);
        }
      }
    }

    if (skipped.isNotEmpty) {
      print('   ⚠️ Skipped ${skipped.length} config entries:');
      for (final s in skipped) {
        print('      - $s');
      }
    }

    return currentTree;
  }

  UspValue _convertJsonValueToUspValue(
    dynamic jsonValue,
    UspValueType targetType,
  ) {
    if (jsonValue is String) {
      switch (targetType) {
        case UspValueType.string:
          return UspValue<String>(jsonValue, UspValueType.string);

        case UspValueType.dateTime:
          DateTime.parse(jsonValue); // Validate format

          return UspValue<String>(jsonValue, UspValueType.dateTime);

        case UspValueType.base64:
          return UspValue<String>(jsonValue, UspValueType.base64);

        case UspValueType.hexBinary:
          return UspValue<String>(jsonValue, UspValueType.hexBinary);

        case UspValueType.int:
        case UspValueType.unsignedInt:
        case UspValueType.long:
        case UspValueType.unsignedLong:
          return UspValue<int>(int.parse(jsonValue), targetType);

        case UspValueType.boolean:
          final lower = jsonValue.toLowerCase();
          if (lower == 'true' || lower == '1') {
            return UspValue<bool>(true, UspValueType.boolean);
          }
          if (lower == 'false' || lower == '0') {
            return UspValue<bool>(false, UspValueType.boolean);
          }
          throw UspException(7003, "Invalid boolean string: '$jsonValue'");
      }
    } else if (jsonValue is int) {
      if ([
        UspValueType.int,
        UspValueType.unsignedInt,
        UspValueType.long,
        UspValueType.unsignedLong,
      ].contains(targetType)) {
        return UspValue<int>(jsonValue, targetType);
      }

      // Consider adding a fallback for int to string conversion if targetType is string

      if (targetType == UspValueType.string) {
        return UspValue<String>(jsonValue.toString(), UspValueType.string);
      }
    } else if (jsonValue is bool) {
      // Changed from `jsonValue is bool && targetType == UspValueType.boolean`

      if (targetType == UspValueType.boolean) {
        return UspValue<bool>(jsonValue, UspValueType.boolean);
      }
    }

    throw UspException(
      7003,
      "Type mismatch: JSON has ${jsonValue.runtimeType}, Schema expects $targetType",
    );
  }
}
