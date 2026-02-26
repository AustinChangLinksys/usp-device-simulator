// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'usp_parameter.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UspParameter<T> _$UspParameterFromJson<T>(
  Map<String, dynamic> json,
  T Function(Object? json) fromJsonT,
) => UspParameter<T>(
  path: UspPath.fromJson(json['path'] as Map<String, dynamic>),
  attributes: json['attributes'] as Map<String, dynamic>? ?? const {},
  value: UspValue<T>.fromJson(
    json['value'] as Map<String, dynamic>,
    (value) => fromJsonT(value),
  ),
  isWritable: json['isWritable'] as bool? ?? false,
);

Map<String, dynamic> _$UspParameterToJson<T>(
  UspParameter<T> instance,
  Object? Function(T value) toJsonT,
) => <String, dynamic>{
  'path': instance.path.toJson(),
  'attributes': instance.attributes,
  'value': instance.value.toJson((value) => toJsonT(value)),
  'isWritable': instance.isWritable,
};
