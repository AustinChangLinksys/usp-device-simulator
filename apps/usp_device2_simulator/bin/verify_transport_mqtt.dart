import 'dart:async';
import 'dart:io';

import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:typed_data/typed_data.dart';
import 'package:usp_protocol_common/usp_protocol_common.dart'; // Import for UspObjectDefinition

void main() async {
  // --- 1. Configuration ---
  const brokerUrl = 'localhost';
  const brokerPort = 1883;
  const agentId = 'proto::agent'; // Agent's ID (Server listens here)
  const controllerId = 'usp-controller-test'; // My ID (I listen here)
  final agentTopic = 'usp/agent/$agentId';
  final replyTopic = 'usp/controller/$controllerId';

  print('===============================================================');
  print(' Verifying command metadata for Device.Reboot() via MQTT');
  print('===============================================================\n');

  final converter = UspProtobufConverter();
  final recordHelper = UspRecordHelper();

  final completer = Completer<void>();
  late MqttServerClient client;

  // --- Helper Functions ---
  void publishRequest(UspMessage reqDto, String msgId) {
    final reqMsg = converter.toProto(reqDto, msgId: msgId);
    final reqRecord = recordHelper.wrap(
      reqMsg,
      fromId: controllerId,
      toId: agentId,
    );
    final builder = MqttClientPayloadBuilder();
    builder.addBuffer(Uint8Buffer()..addAll(reqRecord.writeToBuffer()));

    client.publishMessage(agentTopic, MqttQos.atLeastOnce, builder.payload!);
  }

  // --- Main Execution ---

  try {
    // 1. Connect MQTT Client
    client = MqttServerClient(brokerUrl, controllerId);
    client.port = brokerPort;
    client.keepAlivePeriod = 20;

    final connMess = MqttConnectMessage()
        .withClientIdentifier(controllerId)
        .startClean();
    client.connectionMessage = connMess;

    await client.connect();

    if (client.connectionStatus!.state != MqttConnectionState.connected) {
      throw Exception(
        'MQTT connection failed: ${client.connectionStatus!.state}',
      );
    }
    print('✅ MQTT Connected.');

    // 2. Subscribe to Reply Topic
    client.subscribe(replyTopic, MqttQos.atLeastOnce);

    // 3. Setup Listener (The State Machine)
    client.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      final payloadBytes = (c[0].payload as MqttPublishMessage).payload.message;

      try {
        final resMsg = recordHelper.unwrap(payloadBytes);
        final responseDto = converter.fromProto(resMsg);

        if (responseDto is UspGetSupportedDMResponse) {
          final objDef = responseDto.results['Device.Reboot()'];

          if (objDef != null && objDef.supportedCommands.isNotEmpty) {
            final cmdDef = objDef.supportedCommands['Reboot()'];
            if (cmdDef != null &&
                cmdDef.name == 'Reboot()' &&
                cmdDef.isAsync == false) {
              print(
                '✅ Verification successful: Found command Reboot() with correct metadata.',
              );
              completer.complete();
            } else {
              print('❌ Verification failed: Command metadata is incorrect.');
              exit(1);
            }
          }
        } else if (responseDto is UspErrorResponse) {
          print(
            '❌ Server returned Error: [${responseDto.exception.errorCode}] ${responseDto.exception.message}',
          );
          exit(1);
        } else {
          print(
            '❌ Verification failed: Did not receive a UspGetSupportedDMResponse. Received: ${responseDto.runtimeType}',
          );
          exit(1);
        }
      } catch (e) {
        print('❌ Error in MQTT Listener: $e');
        exit(1);
      }
    });

    // 4. Send GetSupportedDM Request
    print('Sending GetSupportedDM Request for Device.Reboot()...');
    final getSupportedDmRequest = UspGetSupportedDMRequest(
      [UspPath.parse('Device.Reboot()')],
      returnCommands: true,
      firstLevelOnly: false,
    );
    publishRequest(getSupportedDmRequest, "get-supported-dm-req-mqtt");

    // Wait for completion or timeout
    await completer.future.timeout(
      Duration(seconds: 10),
      onTimeout: () {
        print('⏰ Timeout: Test did not complete in 10 seconds.');
        exit(1);
      },
    );
  } catch (e) {
    print('❌ Critical Failure: $e');
    exit(1);
  } finally {
    Future.delayed(
      Duration(milliseconds: 500),
      client.disconnect,
    ); // Ensure connection is closed cleanly
    print('\n👋 Verification finished.');
  }
}
