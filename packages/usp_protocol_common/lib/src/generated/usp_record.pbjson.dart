// This is a generated file - do not edit.
//
// Generated from usp_record.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports
// ignore_for_file: unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use recordDescriptor instead')
const Record$json = {
  '1': 'Record',
  '2': [
    {'1': 'version', '3': 1, '4': 1, '5': 9, '10': 'version'},
    {'1': 'to_id', '3': 2, '4': 1, '5': 9, '10': 'toId'},
    {'1': 'from_id', '3': 3, '4': 1, '5': 9, '10': 'fromId'},
    {
      '1': 'no_session_context',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.usp_record.NoSessionContextRecord',
      '9': 0,
      '10': 'noSessionContext'
    },
    {
      '1': 'session_context',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.usp_record.SessionContextRecord',
      '9': 0,
      '10': 'sessionContext'
    },
    {
      '1': 'websocket_connect',
      '3': 9,
      '4': 1,
      '5': 11,
      '6': '.usp_record.WebSocketConnectRecord',
      '9': 0,
      '10': 'websocketConnect'
    },
    {
      '1': 'mqtt_connect',
      '3': 10,
      '4': 1,
      '5': 11,
      '6': '.usp_record.MQTTConnectRecord',
      '9': 0,
      '10': 'mqttConnect'
    },
    {
      '1': 'stomp_connect',
      '3': 11,
      '4': 1,
      '5': 11,
      '6': '.usp_record.STOMPConnectRecord',
      '9': 0,
      '10': 'stompConnect'
    },
    {
      '1': 'disconnect',
      '3': 12,
      '4': 1,
      '5': 11,
      '6': '.usp_record.DisconnectRecord',
      '9': 0,
      '10': 'disconnect'
    },
    {
      '1': 'uds_connect',
      '3': 13,
      '4': 1,
      '5': 11,
      '6': '.usp_record.UDSConnectRecord',
      '9': 0,
      '10': 'udsConnect'
    },
  ],
  '8': [
    {'1': 'record_type'},
  ],
};

/// Descriptor for `Record`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List recordDescriptor = $convert.base64Decode(
    'CgZSZWNvcmQSGAoHdmVyc2lvbhgBIAEoCVIHdmVyc2lvbhITCgV0b19pZBgCIAEoCVIEdG9JZB'
    'IXCgdmcm9tX2lkGAMgASgJUgZmcm9tSWQSUgoSbm9fc2Vzc2lvbl9jb250ZXh0GAQgASgLMiIu'
    'dXNwX3JlY29yZC5Ob1Nlc3Npb25Db250ZXh0UmVjb3JkSABSEG5vU2Vzc2lvbkNvbnRleHQSSw'
    'oPc2Vzc2lvbl9jb250ZXh0GAUgASgLMiAudXNwX3JlY29yZC5TZXNzaW9uQ29udGV4dFJlY29y'
    'ZEgAUg5zZXNzaW9uQ29udGV4dBJRChF3ZWJzb2NrZXRfY29ubmVjdBgJIAEoCzIiLnVzcF9yZW'
    'NvcmQuV2ViU29ja2V0Q29ubmVjdFJlY29yZEgAUhB3ZWJzb2NrZXRDb25uZWN0EkIKDG1xdHRf'
    'Y29ubmVjdBgKIAEoCzIdLnVzcF9yZWNvcmQuTVFUVENvbm5lY3RSZWNvcmRIAFILbXF0dENvbm'
    '5lY3QSRQoNc3RvbXBfY29ubmVjdBgLIAEoCzIeLnVzcF9yZWNvcmQuU1RPTVBDb25uZWN0UmVj'
    'b3JkSABSDHN0b21wQ29ubmVjdBI+CgpkaXNjb25uZWN0GAwgASgLMhwudXNwX3JlY29yZC5EaX'
    'Njb25uZWN0UmVjb3JkSABSCmRpc2Nvbm5lY3QSPwoLdWRzX2Nvbm5lY3QYDSABKAsyHC51c3Bf'
    'cmVjb3JkLlVEU0Nvbm5lY3RSZWNvcmRIAFIKdWRzQ29ubmVjdEINCgtyZWNvcmRfdHlwZQ==');

@$core.Deprecated('Use noSessionContextRecordDescriptor instead')
const NoSessionContextRecord$json = {
  '1': 'NoSessionContextRecord',
  '2': [
    {'1': 'payload', '3': 1, '4': 1, '5': 12, '10': 'payload'},
  ],
};

/// Descriptor for `NoSessionContextRecord`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List noSessionContextRecordDescriptor =
    $convert.base64Decode(
        'ChZOb1Nlc3Npb25Db250ZXh0UmVjb3JkEhgKB3BheWxvYWQYASABKAxSB3BheWxvYWQ=');

@$core.Deprecated('Use sessionContextRecordDescriptor instead')
const SessionContextRecord$json = {
  '1': 'SessionContextRecord',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 4, '10': 'sessionId'},
    {'1': 'sequence_id', '3': 2, '4': 1, '5': 4, '10': 'sequenceId'},
    {'1': 'expected_id', '3': 3, '4': 1, '5': 4, '10': 'expectedId'},
    {'1': 'retransmit_id', '3': 4, '4': 1, '5': 4, '10': 'retransmitId'},
    {
      '1': 'payload_security',
      '3': 5,
      '4': 1,
      '5': 12,
      '9': 0,
      '10': 'payloadSecurity'
    },
    {
      '1': 'payload_no_security',
      '3': 6,
      '4': 1,
      '5': 12,
      '9': 0,
      '10': 'payloadNoSecurity'
    },
  ],
  '8': [
    {'1': 'payload'},
  ],
};

/// Descriptor for `SessionContextRecord`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sessionContextRecordDescriptor = $convert.base64Decode(
    'ChRTZXNzaW9uQ29udGV4dFJlY29yZBIdCgpzZXNzaW9uX2lkGAEgASgEUglzZXNzaW9uSWQSHw'
    'oLc2VxdWVuY2VfaWQYAiABKARSCnNlcXVlbmNlSWQSHwoLZXhwZWN0ZWRfaWQYAyABKARSCmV4'
    'cGVjdGVkSWQSIwoNcmV0cmFuc21pdF9pZBgEIAEoBFIMcmV0cmFuc21pdElkEisKEHBheWxvYW'
    'Rfc2VjdXJpdHkYBSABKAxIAFIPcGF5bG9hZFNlY3VyaXR5EjAKE3BheWxvYWRfbm9fc2VjdXJp'
    'dHkYBiABKAxIAFIRcGF5bG9hZE5vU2VjdXJpdHlCCQoHcGF5bG9hZA==');

@$core.Deprecated('Use webSocketConnectRecordDescriptor instead')
const WebSocketConnectRecord$json = {
  '1': 'WebSocketConnectRecord',
};

/// Descriptor for `WebSocketConnectRecord`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List webSocketConnectRecordDescriptor =
    $convert.base64Decode('ChZXZWJTb2NrZXRDb25uZWN0UmVjb3Jk');

@$core.Deprecated('Use mQTTConnectRecordDescriptor instead')
const MQTTConnectRecord$json = {
  '1': 'MQTTConnectRecord',
  '2': [
    {
      '1': 'version',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.usp_record.MQTTConnectRecord.MQTTVersion',
      '10': 'version'
    },
    {'1': 'subscribed_topic', '3': 2, '4': 1, '5': 9, '10': 'subscribedTopic'},
  ],
  '4': [MQTTConnectRecord_MQTTVersion$json],
};

@$core.Deprecated('Use mQTTConnectRecordDescriptor instead')
const MQTTConnectRecord_MQTTVersion$json = {
  '1': 'MQTTVersion',
  '2': [
    {'1': 'V3_1_1', '2': 0},
    {'1': 'V5', '2': 1},
  ],
};

/// Descriptor for `MQTTConnectRecord`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List mQTTConnectRecordDescriptor = $convert.base64Decode(
    'ChFNUVRUQ29ubmVjdFJlY29yZBJDCgd2ZXJzaW9uGAEgASgOMikudXNwX3JlY29yZC5NUVRUQ2'
    '9ubmVjdFJlY29yZC5NUVRUVmVyc2lvblIHdmVyc2lvbhIpChBzdWJzY3JpYmVkX3RvcGljGAIg'
    'ASgJUg9zdWJzY3JpYmVkVG9waWMiIQoLTVFUVFZlcnNpb24SCgoGVjNfMV8xEAASBgoCVjUQAQ'
    '==');

@$core.Deprecated('Use sTOMPConnectRecordDescriptor instead')
const STOMPConnectRecord$json = {
  '1': 'STOMPConnectRecord',
  '2': [
    {
      '1': 'version',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.usp_record.STOMPConnectRecord.STOMPVersion',
      '10': 'version'
    },
    {
      '1': 'subscribed_destination',
      '3': 2,
      '4': 1,
      '5': 9,
      '10': 'subscribedDestination'
    },
  ],
  '4': [STOMPConnectRecord_STOMPVersion$json],
};

@$core.Deprecated('Use sTOMPConnectRecordDescriptor instead')
const STOMPConnectRecord_STOMPVersion$json = {
  '1': 'STOMPVersion',
  '2': [
    {'1': 'V1_2', '2': 0},
  ],
};

/// Descriptor for `STOMPConnectRecord`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sTOMPConnectRecordDescriptor = $convert.base64Decode(
    'ChJTVE9NUENvbm5lY3RSZWNvcmQSRQoHdmVyc2lvbhgBIAEoDjIrLnVzcF9yZWNvcmQuU1RPTV'
    'BDb25uZWN0UmVjb3JkLlNUT01QVmVyc2lvblIHdmVyc2lvbhI1ChZzdWJzY3JpYmVkX2Rlc3Rp'
    'bmF0aW9uGAIgASgJUhVzdWJzY3JpYmVkRGVzdGluYXRpb24iGAoMU1RPTVBWZXJzaW9uEggKBF'
    'YxXzIQAA==');

@$core.Deprecated('Use uDSConnectRecordDescriptor instead')
const UDSConnectRecord$json = {
  '1': 'UDSConnectRecord',
};

/// Descriptor for `UDSConnectRecord`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List uDSConnectRecordDescriptor =
    $convert.base64Decode('ChBVRFNDb25uZWN0UmVjb3Jk');

@$core.Deprecated('Use disconnectRecordDescriptor instead')
const DisconnectRecord$json = {
  '1': 'DisconnectRecord',
  '2': [
    {'1': 'reason', '3': 1, '4': 1, '5': 9, '10': 'reason'},
    {'1': 'reason_code', '3': 2, '4': 1, '5': 7, '10': 'reasonCode'},
  ],
};

/// Descriptor for `DisconnectRecord`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List disconnectRecordDescriptor = $convert.base64Decode(
    'ChBEaXNjb25uZWN0UmVjb3JkEhYKBnJlYXNvbhgBIAEoCVIGcmVhc29uEh8KC3JlYXNvbl9jb2'
    'RlGAIgASgHUgpyZWFzb25Db2Rl');
