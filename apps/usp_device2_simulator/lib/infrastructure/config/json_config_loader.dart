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

    // We will "evolve" this tree through updates
    DeviceTree currentTree = initialTree;
    final pathResolver = PathResolver();

    for (final entry in jsonMap.entries) {
      final pathStr = entry.key;
      final jsonValue = entry.value;
      final path = UspPath.parse(pathStr);

      // 1. Find the target node in the current tree (to get its expected type)
      final nodes = pathResolver.resolve<UspNode>(currentTree.root, path);
      
      if (nodes.isEmpty) {
        throw UspException(7002, 'Path not found in DeviceTree: $pathStr');
      }

      for (final node in nodes) {
        if (node is UspParameter) {
          final expectedType = node.value.type;
          UspValue newUspValue;

          try {
            // Helper: Convert JSON value to UspValue
            newUspValue = _convertJsonValueToUspValue(jsonValue, expectedType);
          } catch (e) {
            throw UspException(7003, 'Invalid value for $pathStr: $e');
          }

          // 2. Create an updated Parameter instance (Copy-on-Write)
          final newParam = node.copyWith(value: newUspValue);
          
          // 3. Directly call DeviceTree.updateNode
          // DeviceTree will handle the immutable tree structure replacement
          currentTree = currentTree.updateNode(newParam);
        }
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
          return UspValue<int>(int.parse(jsonValue), targetType);

        case UspValueType.boolean:
          if (jsonValue.toLowerCase() == 'true') {
            return UspValue<bool>(true, UspValueType.boolean);
          }
          if (jsonValue.toLowerCase() == 'false') {
            return UspValue<bool>(false, UspValueType.boolean);
          }
          throw UspException(7003, "Invalid boolean string: '$jsonValue'");

        default:
          throw UspException(7003, "Cannot convert String to $targetType");
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
