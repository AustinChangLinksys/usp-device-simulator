import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:usp_protocol_common/src/generated/usp_msg.pb.dart' as pb_msg;
import 'package:usp_protocol_common/usp_protocol_common.dart';

void main(List<String> args) async {
  final baseUrl = 'http://localhost:8081';

  print('1. Testing Login to get Token...');
  final loginResponse = await http.post(
    Uri.parse('$baseUrl/api/v1/auth/login'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({}),
  );

  if (loginResponse.statusCode != 200) {
    print('❌ Login failed: ${loginResponse.statusCode}');
    exit(1);
  }

  final loginBody = jsonDecode(loginResponse.body);
  print('✅ Login successful. Response: $loginBody');

  final token = loginBody['token'] as String;
  final cookieHeader =
      loginResponse.headers['set-cookie']?.split(';').first ??
      'access_token=$token';

  print('\n2. Constructing USP Protobuf Payload...');

  final converter = UspProtobufConverter();

  final getRequest = pb_msg.Get()..paramPaths.add('Device.DeviceInfo.');

  final uspMsg = pb_msg.Msg()
    ..header = (pb_msg.Header()..msgId = 'get-device-info-req-http-1')
    ..body = (pb_msg.Body()..request = (pb_msg.Request()..get = getRequest));

  final payload = uspMsg.writeToBuffer();

  print('3. Sending POST request to /api/v1/usp...');
  final uspResponse = await http.post(
    Uri.parse('$baseUrl/api/v1/usp'),
    headers: {
      'Content-Type': 'application/x-protobuf',
      // We can use either Cookie or Authorization header based on HttpMtpService config
      'Cookie': cookieHeader,
    },
    body: payload,
  );

  if (uspResponse.statusCode != 200) {
    print(
      '❌ USP Request failed: ${uspResponse.statusCode} - ${uspResponse.body}',
    );
    exit(1);
  }

  print('✅ Received 200 OK Response.');

  // Try to parse the protobuf response
  try {
    final responseBytes = uspResponse.bodyBytes;
    final responseUspMsg = pb_msg.Msg.fromBuffer(responseBytes);
    final responseDto = converter.fromProto(responseUspMsg);

    if (responseDto is UspGetResponse) {
      print(
        '✅ Parsed UspGetResponse payload. Resolved paths: ${responseDto.results.keys.toList()}',
      );
      if (responseDto.results.isNotEmpty) {
        print(
          '✅ Verification successful: Fetched ${responseDto.results.length} parameters from Device.DeviceInfo. via HTTP POST.',
        );
      } else {
        print('❌ Verification failed: Did not find DeviceInfo parameters.');
        exit(1);
      }
    } else {
      print('❌ Verification failed: Did not receive a UspGetResponse.');
      exit(1);
    }
  } catch (e) {
    print('❌ Failed to parse USP Response: $e');
    exit(1);
  }
}
