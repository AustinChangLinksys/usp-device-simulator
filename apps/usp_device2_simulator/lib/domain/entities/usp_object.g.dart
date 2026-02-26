// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'usp_object.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UspObject _$UspObjectFromJson(Map<String, dynamic> json) => UspObject(
  path: UspPath.fromJson(json['path'] as Map<String, dynamic>),
  attributes: json['attributes'] as Map<String, dynamic>? ?? const {},
  children:
      (json['children'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(
          k,
          const UspNodeConverter().fromJson(e as Map<String, dynamic>),
        ),
      ) ??
      const {},
  isMultiInstance: json['isMultiInstance'] as bool? ?? false,
  nextInstanceId: (json['nextInstanceId'] as num?)?.toInt() ?? 1,
  minEntries: (json['minEntries'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$UspObjectToJson(UspObject instance) => <String, dynamic>{
  'path': instance.path.toJson(),
  'attributes': instance.attributes,
  'children': instance.children.map(
    (k, e) => MapEntry(k, const UspNodeConverter().toJson(e)),
  ),
  'isMultiInstance': instance.isMultiInstance,
  'nextInstanceId': instance.nextInstanceId,
  'minEntries': instance.minEntries,
};
