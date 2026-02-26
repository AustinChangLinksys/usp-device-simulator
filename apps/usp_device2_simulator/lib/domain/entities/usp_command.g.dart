// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'usp_command.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UspCommand _$UspCommandFromJson(Map<String, dynamic> json) => UspCommand(
  path: UspPath.fromJson(json['path'] as Map<String, dynamic>),
  attributes: json['attributes'] as Map<String, dynamic>? ?? const {},
);

Map<String, dynamic> _$UspCommandToJson(UspCommand instance) =>
    <String, dynamic>{
      'path': instance.path.toJson(),
      'attributes': instance.attributes,
    };
