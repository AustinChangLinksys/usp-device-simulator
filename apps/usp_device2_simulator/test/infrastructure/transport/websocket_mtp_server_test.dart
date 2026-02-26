import 'dart:io';
import 'dart:async';
import 'package:test/test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:usp_protocol_common/usp_protocol_common.dart';
import 'package:usp_device2_simulator/infrastructure/adapter/usp_message_adapter.dart';
import 'package:usp_device2_simulator/infrastructure/transport/websocket_mtp_service.dart';
import 'package:usp_protocol_common/src/generated/usp_record.pb.dart'
    as pb_record;

// Mock Adapter
class MockUspMessageAdapter extends Mock implements UspMessageAdapter {}

// Fakes
class FakeUspMessage extends Fake implements UspMessage {}

void main() {
  group('WebSocketMtpServer', () {
    late WebSocketMtpService server;
    late MockUspMessageAdapter mockAdapter;

    // Tools for test client
    final converter = UspProtobufConverter();
    final recordHelper = UspRecordHelper();

    setUpAll(() {
      registerFallbackValue(FakeUspMessage());
    });

    setUp(() {
      mockAdapter = MockUspMessageAdapter();
      server = WebSocketMtpService(mockAdapter);
    });

    tearDown(() async {
      await server.stop();
    });

    test('should accept connection, process request, and send response', () async {
      // 1. Arrange: Start server on random port (0)
      await server.start(port: 0);
      // Note: WebSocketMtpServer prints the port, but we assume it binds successfully.
      // Since we pass 0, we assume it picks an available port.
      // Ideally, WebSocketMtpServer should expose the actual bound port getter.

      // Let's try binding a specific port for test stability: 8085
      await server.stop();
      await server.start(port: 8085);
      final serverUrl = 'ws://localhost:8085';

      // Mock Adapter Behavior: Return a dummy GetResponse
      final expectedResponseDto = UspGetResponse({
        UspPath.parse('Device.Test'): UspValue('OK', UspValueType.string),
      });
      when(
        () => mockAdapter.handleRequest(any()),
      ).thenAnswer((_) async => expectedResponseDto);

      // 2. Act: Connect Client
      final clientSocket = await WebSocket.connect(serverUrl);
      final completer = Completer<UspMessage>();

      clientSocket.listen((data) {
        // Client Receive Logic
        final resRecord = recordHelper.unwrap(data as List<int>);
        final resDto = converter.fromProto(resRecord);
        completer.complete(resDto);
      });

      // Client Send Logic
      final reqDto = UspGetRequest([UspPath.parse('Device.Test')]);
      final reqMsg = converter.toProto(reqDto, msgId: "test-id-1");
      final reqRecord = recordHelper.wrap(
        reqMsg,
        fromId: "proto::test-client",
        toId: "proto::simulator",
      );

      clientSocket.add(reqRecord.writeToBuffer());

      // 3. Assert
      final receivedResponse = await completer.future.timeout(
        Duration(seconds: 2),
      );

      expect(receivedResponse, isA<UspGetResponse>());
      expect((receivedResponse as UspGetResponse).results.isNotEmpty, true);

      // Verify Adapter was called
      verify(() => mockAdapter.handleRequest(any())).called(1);

      await clientSocket.close();
    });

    test('should handle malformed data gracefully', () async {
      await server.start(port: 8086);
      final clientSocket = await WebSocket.connect('ws://localhost:8086');

      // Send garbage data
      clientSocket.add([1, 2, 3, 4, 5]);

      // Server should not crash.
      // We can verify this by sending a valid request afterwards and checking if it responds.
      // Or verify that no call was made to adapter.

      await Future.delayed(Duration(milliseconds: 100)); // Wait a bit
      verifyNever(() => mockAdapter.handleRequest(any()));

      await clientSocket.close();
    });

    test('should reply to the correct sender_id', () async {
      await server.start(port: 8087);
      final clientSocket = await WebSocket.connect('ws://localhost:8087');

      final myId = "proto::special-client-id";

      // Setup Request
      final reqDto = UspGetRequest([]);
      final reqMsg = converter.toProto(reqDto, msgId: "1");
      final reqRecord = recordHelper.wrap(reqMsg, fromId: myId, toId: "sim");

      // Setup Mock Response
      when(
        () => mockAdapter.handleRequest(any()),
      ).thenAnswer((_) async => UspGetResponse({}));

      clientSocket.add(reqRecord.writeToBuffer());

      final completer = Completer<String>();
      clientSocket.listen((data) {
        final record = pb_record.Record.fromBuffer(data as List<int>);
        completer.complete(record.toId); // We check who the server sent it to
      });

      final toIdReceived = await completer.future;
      expect(
        toIdReceived,
        myId,
        reason: "Server should reply to the sender's ID",
      );

      await clientSocket.close();
    });
  });
}
