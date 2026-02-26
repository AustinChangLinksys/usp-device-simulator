import 'package:json_annotation/json_annotation.dart';
import 'package:usp_device2_simulator/domain/entities/usp_command.dart';
import 'package:usp_device2_simulator/domain/entities/usp_node.dart';
import 'package:usp_device2_simulator/domain/entities/usp_object.dart';
import 'package:usp_device2_simulator/domain/entities/usp_parameter.dart';

class UspNodeConverter extends JsonConverter<UspNode, Map<String, dynamic>> {
  const UspNodeConverter();

  @override
  UspNode fromJson(Map<String, dynamic> json) {
    // Determine the actual type based on a discriminator field
    final type = json['_type'] as String?;
    switch (type) {
      case 'UspObject':
        return UspObject.fromJson(json);

      case 'UspCommand':
        return UspCommand.fromJson(json);

      case 'UspParameter':
        final valueMap = json['value'] as Map<String, dynamic>;
        final valueTypeStr = valueMap['type'] as String;

        switch (valueTypeStr) {
          case 'string':
          case 'base64':
          case 'hexBinary':
            return UspParameter<String>.fromJson(json, (x) => x as String);
          case 'dateTime':
            return UspParameter<DateTime>.fromJson(
              json,
              (x) => DateTime.parse(x as String),
            );


          case 'int':
          case 'unsignedInt':
          case 'long':
          case 'unsignedLong':
            return UspParameter<int>.fromJson(json, (x) => x as int);
          case 'boolean':
            return UspParameter<bool>.fromJson(json, (x) => x as bool);
          default:
            // Fallback for unknown types
            return UspParameter.fromJson(json, (x) => x);
        }

      default:
        throw UnimplementedError('Unknown _type: $type');
    }
  }

  @override
  Map<String, dynamic> toJson(UspNode object) {
    if (object is UspObject) {
      return {...object.toJson(), '_type': 'UspObject'};
    } else if (object is UspCommand) {
      return {...object.toJson(), '_type': 'UspCommand'};
    } else if (object is UspParameter) {
      final json = object.toJson((value) {
        if (value is DateTime) return value.toIso8601String();
        return value;
      });
      return {...json, '_type': 'UspParameter'};
    } else {
      throw UnimplementedError('Unknown UspNode type: ${object.runtimeType}');
    }
  }
}
