import 'dart:io';
import 'dart:async';
import 'package:usp_protocol_common/usp_protocol_common.dart';

void main() async {
  const serverUrl = 'ws://localhost:8080';

  print('===============================================================');
  print(' Verifying command metadata for Device.Reboot() via WebSocket');
  print('===============================================================');

  final converter = UspProtobufConverter();
  final recordHelper = UspRecordHelper();

  WebSocket? socket;
  final completer = Completer<void>();

  try {
    // 1. Connect
    print('🔌 Connecting to $serverUrl ...');
    socket = await WebSocket.connect(serverUrl);
    print('✅ Connected!\n');

    // 2. Prepare GetSupportedDM Request
    print('Requesting command metadata for Device.Reboot()...');

    final getSupportedDmRequest = UspGetSupportedDMRequest(
      [UspPath.parse('Device.Reboot()')],
      returnCommands: true,
      firstLevelOnly: false,
    );
    
    // Packing
    final reqMsg = converter.toProto(getSupportedDmRequest, msgId: "get-supported-dm-req-ws");
    final reqRecord = recordHelper.wrap(
      reqMsg,
      fromId: "proto::verifier",
      toId: "proto::simulator",
    );

    // 3. Send
    socket.add(reqRecord.writeToBuffer());

    // 4. Receive and Verify
    socket.listen(
      (data) {
        if (data is List<int>) {
          try {
            final resMsg = recordHelper.unwrap(data);
            final responseDto = converter.fromProto(resMsg);

            if (responseDto is UspGetSupportedDMResponse) {
              final objDef = responseDto.results['Device.Reboot()'];

              if (objDef != null && objDef.supportedCommands.isNotEmpty) {
                final cmdDef = objDef.supportedCommands['Reboot()'];
                if (cmdDef != null && cmdDef.name == 'Reboot()' && cmdDef.isAsync == false) {
                  print('✅ Verification successful: Found command Reboot() with correct metadata.');
                  completer.complete();
                } else {
                  print('❌ Verification failed: Command metadata is incorrect.');
                  exit(1);
                }
              } else {
                print('❌ Verification failed: Command definition not found.');
                exit(1);
              }
            } else if (responseDto is UspErrorResponse) {
              print(
                '❌ Server returned Error: [${responseDto.exception.errorCode}] ${responseDto.exception.message}',
              );
              exit(1);
            } else {
              print('❌ Verification failed: Did not receive a UspGetSupportedDMResponse. Received: ${responseDto.runtimeType}');
              exit(1);
            }
          } catch (e) {
            print('❌ Failed to parse response: $e');
            exit(1);
          }
        }
      },
      onError: (e) {
        print('❌ WebSocket Error: $e');
        exit(1);
      },
      onDone: () {
        if (!completer.isCompleted) completer.complete();
      },
    );

    await completer.future.timeout(
      Duration(seconds: 5),
      onTimeout: () {
        print('⏰ Timeout: Server did not respond.');
        exit(1);
      },
    );
  } catch (e) {
    print('❌ Connection failed: $e');
    exit(1);
  } finally {
    await socket?.close();
    print('\n👋 Verification finished.');
  }
}