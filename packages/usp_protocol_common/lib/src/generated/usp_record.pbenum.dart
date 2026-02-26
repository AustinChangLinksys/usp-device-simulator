// This is a generated file - do not edit.
//
// Generated from usp_record.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class MQTTConnectRecord_MQTTVersion extends $pb.ProtobufEnum {
  static const MQTTConnectRecord_MQTTVersion V3_1_1 =
      MQTTConnectRecord_MQTTVersion._(0, _omitEnumNames ? '' : 'V3_1_1');
  static const MQTTConnectRecord_MQTTVersion V5 =
      MQTTConnectRecord_MQTTVersion._(1, _omitEnumNames ? '' : 'V5');

  static const $core.List<MQTTConnectRecord_MQTTVersion> values =
      <MQTTConnectRecord_MQTTVersion>[
    V3_1_1,
    V5,
  ];

  static final $core.List<MQTTConnectRecord_MQTTVersion?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 1);
  static MQTTConnectRecord_MQTTVersion? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const MQTTConnectRecord_MQTTVersion._(super.value, super.name);
}

class STOMPConnectRecord_STOMPVersion extends $pb.ProtobufEnum {
  static const STOMPConnectRecord_STOMPVersion V1_2 =
      STOMPConnectRecord_STOMPVersion._(0, _omitEnumNames ? '' : 'V1_2');

  static const $core.List<STOMPConnectRecord_STOMPVersion> values =
      <STOMPConnectRecord_STOMPVersion>[
    V1_2,
  ];

  static final $core.List<STOMPConnectRecord_STOMPVersion?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 0);
  static STOMPConnectRecord_STOMPVersion? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const STOMPConnectRecord_STOMPVersion._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
