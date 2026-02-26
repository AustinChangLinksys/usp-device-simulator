import 'dart:convert'; // For JsonEncoder
import 'package:grpc/grpc.dart';
import 'package:usp_protocol_common/usp_protocol_common.dart';

void main(List<String> args) async {
  final channel = ClientChannel(
    'localhost',
    port: 50051,
    options: const ChannelOptions(credentials: ChannelCredentials.insecure()),
  );

  final stub = UspTransportServiceClient(channel);
  final converter = UspProtobufConverter();
  final recordHelper = UspRecordHelper();

  print('===============================================================');
  print('📜 USP Metadata Dumper (GetSupportedDM)');
  print('===============================================================\n');

  try {
    // 1. Prepare Request: GetSupportedDM("Device.", firstLevelOnly: false)
    // firstLevelOnly: false means recursive fetching of the entire tree
    final reqDto = UspGetSupportedDMRequest(
      [UspPath.parse('Device.')],
      firstLevelOnly: false, 
      returnCommands: true,
      returnParams: true,
    );

    // 2. Wrap and Send
    final reqMsg = converter.toProto(reqDto, msgId: "meta-dump-001");
    final reqRecord = recordHelper.wrap(
        reqMsg, fromId: "proto::verifier", toId: "proto::agent");
        
    final transportReq = UspTransportRequest()
      ..uspRecordPayload = reqRecord.writeToBuffer();

    print('📡 Sending Request...');
    final transportRes = await stub.sendUspMessage(transportReq);

    // 3. Unwrap Response
    final resMsg = recordHelper.unwrap(transportRes.uspRecordResponse);
    final resDto = converter.fromProto(resMsg);

    if (resDto is UspGetSupportedDMResponse) {
      print('✅ Received Metadata. Converting to JSON...\n');
      
      // 4. Convert to JSON and Print
      _printAsJson(resDto);
      
    } else if (resDto is UspErrorResponse) {
      print('❌ Error: ${resDto.exception.message}');
    }

  } catch (e) {
    print('❌ Critical Error: $e');
  } finally {
    await channel.shutdown();
  }
}

/// Helper function: Convert complex DTO to Map and print Pretty JSON
void _printAsJson(UspGetSupportedDMResponse response) {
  final jsonMap = <String, dynamic>{};

  // Convert DTO to a plain Map structure (as DTO might not implement toJson or have a readable structure)
  response.results.forEach((path, objDef) {
    jsonMap[path] = {
      "access": objDef.access,
      "isMultiInstance": objDef.isMultiInstance,
      "Parameters": objDef.supportedParams.map((name, def) => MapEntry(name, {
            "type": def.type.name,
            "access": def.isWritable ? "RW" : "RO",
            // "constraints": ... if any
          })),
      "Commands": objDef.supportedCommands.map((name, def) => MapEntry(name, {
            "async": def.isAsync,
            "inputs": def.inputArgs.keys.toList(),
            "outputs": def.outputArgs.keys.toList(),
          })),
    };
  });

  // Use JsonEncoder for indentation
  final encoder = JsonEncoder.withIndent('  ');
  print(encoder.convert(jsonMap));
  
  print('\n---------------------------------------------------------------');
  print('📊 Summary:');
  print('   Objects: ${response.results.length}');
  
  // Count Commands
  int cmdCount = 0;
  for (final objDef in response.results.values) {
    cmdCount += objDef.supportedCommands.length;
  }
  print('   Commands: $cmdCount');
  print('---------------------------------------------------------------');
}