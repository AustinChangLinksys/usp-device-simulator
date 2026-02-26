import 'dart:io';

import 'package:grpc/grpc.dart';
import 'package:usp_protocol_common/src/generated/usp_msg.pb.dart' as pb_msg;
import 'package:usp_protocol_common/usp_protocol_common.dart';

void main(List<String> args) async {
  final channel = ClientChannel(
    'localhost',
    port: 50051,
    options: const ChannelOptions(
      credentials: ChannelCredentials.insecure(),
    ),
  );

  final stub = UspTransportServiceClient(channel);
  final recordHelper = UspRecordHelper();
  final converter = UspProtobufConverter();

  // Construct GetSupportedDM request for the command
  final getSupportedDmRequest = pb_msg.GetSupportedDM()
    ..objPaths.add('Device.Reboot()')
    ..firstLevelOnly = false;

  final uspMsg = pb_msg.Msg()
    ..header = (pb_msg.Header()..msgId = 'get-supported-dm-req-1')
    ..body = (pb_msg.Body()..request = (pb_msg.Request()..getSupportedDm = getSupportedDmRequest));
    
  final uspRecord = recordHelper.wrap(
    uspMsg,
    fromId: 'controller-client',
    toId: 'device2-simulator',
  );

  final request = UspTransportRequest()
    ..uspRecordPayload = uspRecord.writeToBuffer();

  print('Verifying command metadata for Device.Reboot()...');

  final UspTransportResponse response = await stub.sendUspMessage(request);

  final responseUspMsg = recordHelper.unwrap(response.uspRecordResponse);
  final responseDto = converter.fromProto(responseUspMsg);

  if (responseDto is UspGetSupportedDMResponse) {
    final objDef = responseDto.results['Device.Reboot()'];

    if (objDef != null && objDef.supportedCommands.isNotEmpty) {
      final cmdDef = objDef.supportedCommands['Reboot()'];
      if (cmdDef != null && cmdDef.name == 'Reboot()' && !cmdDef.isAsync) {
        print('✅ Verification successful: Found command Reboot() with correct metadata.');
      } else {
        print('❌ Verification failed: Command metadata is incorrect.');
        exit(1);
      }
    } else {
      print('❌ Verification failed: Command definition not found.');
      exit(1);
    }
  } else {
    print('❌ Verification failed: Did not receive a UspGetSupportedDMResponse.');
    exit(1);
  }

  await channel.shutdown();
}
