import 'dart:async';
import 'package:test/test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:usp_device2_simulator/infrastructure/transport/mqtt_mtp_service.dart';
import 'package:typed_data/typed_data.dart';
import 'package:usp_protocol_common/usp_protocol_common.dart';
import 'package:usp_protocol_common/src/generated/usp_msg.pb.dart' as usp_msg;
import 'package:usp_protocol_common/src/generated/usp_record.pb.dart'
    as usp_record;

import '../../mocks.dart';

void main() {
  setUpAll(() {
    registerFallbackValue(MqttQos.atMostOnce);
    registerFallbackValue(UspGetRequest([]));
    registerFallbackValue(Uint8Buffer());
  });
  group('MqttMtpService', () {
    late MqttMtpService service;
    late MockUspMessageAdapter mockMessageAdapter;
    late MockMqttServerClient mockMqttClient;
    late StreamController<List<MqttReceivedMessage<MqttMessage>>>
    updatesController;
    setUp(() {
      mockMessageAdapter = MockUspMessageAdapter();
      mockMqttClient = MockMqttServerClient();
      updatesController =
          StreamController<List<MqttReceivedMessage<MqttMessage>>>.broadcast();

      when(
        () => mockMqttClient.updates,
      ).thenAnswer((_) => updatesController.stream);

      service = MqttMtpService.internal(mockMessageAdapter, mockMqttClient);
    });

    test('connect succeeds on the first attempt', () async {
      when(() => mockMqttClient.connect()).thenAnswer((_) async => null);
      when(() => mockMqttClient.connectionStatus).thenReturn(
        MqttClientConnectionStatus()..state = MqttConnectionState.connected,
      );
      when(() => mockMqttClient.updates).thenAnswer((_) => Stream.empty());
      when(() => mockMqttClient.onDisconnected = any()).thenReturn(null);

      await service.connect();

      expect(service.connectionState, MqttConnectionState.connected);
      verify(() => mockMqttClient.connect()).called(1);
    });

    test('connect retries on failure and then succeeds', () async {
      var connectCallCount = 0;
      when(() => mockMqttClient.connect()).thenAnswer((_) {
        connectCallCount++;
        if (connectCallCount == 1) {
          throw Exception('Connection failed');
        }
        return Future.value(null);
      });

      final connectionStatusResponses = [
        MqttClientConnectionStatus()..state = MqttConnectionState.connected,
        MqttClientConnectionStatus()..state = MqttConnectionState.connected,
      ];
      var connectionStatusCallCount = 0;
      when(() => mockMqttClient.connectionStatus).thenAnswer((_) {
        final response = connectionStatusResponses[connectionStatusCallCount];
        if (connectionStatusCallCount < connectionStatusResponses.length - 1) {
          connectionStatusCallCount++;
        }
        return response;
      });
      when(() => mockMqttClient.updates).thenAnswer((_) => Stream.empty());
      when(() => mockMqttClient.onDisconnected = any()).thenReturn(null);

      await service.connect();

      expect(service.connectionState, MqttConnectionState.connected);
      verify(() => mockMqttClient.connect()).called(2);
    });

    test('connect gives up after max retries', () async {
      when(
        () => mockMqttClient.connect(),
      ).thenThrow(Exception('Connection failed'));
      when(() => mockMqttClient.connectionStatus).thenReturn(
        MqttClientConnectionStatus()..state = MqttConnectionState.faulted,
      );
      when(() => mockMqttClient.disconnect()).thenAnswer((_) async {});
      when(() => mockMqttClient.onDisconnected = any()).thenReturn(null);

      await expectLater(service.connect(), throwsException);

      verify(() => mockMqttClient.connect()).called(3);
      verify(() => mockMqttClient.disconnect()).called(1);
    });

    test('MqttMtpService onDisconnected triggers reconnect', () async {
      // Arrange
      // 1. Simulate initial connected state
      final connectedStatus = MqttClientConnectionStatus()
        ..state = MqttConnectionState.connected;
      when(() => mockMqttClient.connectionStatus).thenReturn(connectedStatus);
      when(
        () => mockMqttClient.connect(),
      ).thenAnswer((_) async => null); // Successful connect

      // 2. Start the service (First Connect)
      await service.start();

      // 3. Simulate disconnected state (so the reconnect logic inside _onDisconnected proceeds)
      final disconnectedStatus = MqttClientConnectionStatus()
        ..state = MqttConnectionState.faulted; // Simulate a fault/crash
      when(
        () => mockMqttClient.connectionStatus,
      ).thenReturn(disconnectedStatus);

      // Act
      // We need to verify that the setter was called and get the function passed to it.
      final captured = verify(
        () => mockMqttClient.onDisconnected = captureAny(),
      ).captured;

      // Ensure we actually captured something
      expect(
        captured,
        isNotEmpty,
        reason: "onDisconnected callback was not set",
      );

      final onDisconnectedCallback = captured.last as void Function();

      // Manually trigger the callback to simulate a disconnection event
      onDisconnectedCallback();

      // Allow the async connect() inside the callback to be scheduled
      await Future.delayed(Duration.zero);

      // Assert
      // Should be called twice: 1 (start) + 1 (reconnect)
      verify(() => mockMqttClient.connect()).called(2);
    });

    test('subscribe succeeds when connected', () async {
      // Arrange
      when(() => mockMqttClient.connectionStatus).thenReturn(
        MqttClientConnectionStatus()..state = MqttConnectionState.connected,
      );
      // Simulate subscribe returns a Subscription object (although usually no return value is needed, but mocktail sometimes needs it)
      when(
        () => mockMqttClient.subscribe(any(), any()),
      ).thenReturn(Subscription());

      // Act
      await service.subscribe();

      // Assert
      verify(
        () => mockMqttClient.subscribe('test/topic', MqttQos.atLeastOnce),
      ).called(1);
    });

    test('subscribe does nothing when not connected', () async {
      when(() => mockMqttClient.connectionStatus).thenReturn(
        MqttClientConnectionStatus()..state = MqttConnectionState.disconnected,
      );

      await service.subscribe();

      verifyNever(() => mockMqttClient.subscribe(any(), any()));
    });

    test(
      'handleMessage processes a valid message and publishes a response',
      () async {
        final streamController =
            StreamController<
              List<MqttReceivedMessage<MqttMessage>>
            >.broadcast();
        when(
          () => mockMqttClient.updates,
        ).thenAnswer((_) => streamController.stream);

        // Connect and set up listener
        when(() => mockMqttClient.connect()).thenAnswer((_) async => null);
        when(() => mockMqttClient.connectionStatus).thenReturn(
          MqttClientConnectionStatus()..state = MqttConnectionState.connected,
        );
        when(() => mockMqttClient.onDisconnected = any()).thenReturn(null);
        await service.connect();

        // Mock the adapter response
        final response = UspGetResponse({});
        when(
          () => mockMessageAdapter.handleRequest(any()),
        ).thenAnswer((_) async => response);

        // Mock the publish call
        when(
          () => mockMqttClient.publishMessage(any(), any(), any()),
        ).thenReturn(1);

        // Create a fake incoming message
        final get = usp_msg.Get()
          ..paramPaths.add('Device.DeviceInfo.Manufacturer');
        final uspMsg = usp_msg.Msg(
          header: usp_msg.Header(msgId: '1'),
          body: usp_msg.Body(request: usp_msg.Request(get: get)),
        );
        final record = usp_record.Record(
          version: '1.1',
          toId: 'usp-agent-dart',
          fromId: 'usp-controller-dart',
          noSessionContext: usp_record.NoSessionContextRecord(
            payload: uspMsg.writeToBuffer(),
          ),
        );

        final builder = MqttClientPayloadBuilder();
        builder.addBuffer(Uint8Buffer()..addAll(record.writeToBuffer()));
        final mqttMessage = MqttPublishMessage()
            .toTopic('usp/agent/proto::agent')
            .publishData(builder.payload!);

        streamController.add([
          MqttReceivedMessage('usp/agent/proto::agent', mqttMessage),
        ]);

        await untilCalled(
          () => mockMqttClient.publishMessage(any(), any(), any()),
        );

        verify(
          () => mockMqttClient.publishMessage(
            'usp/controller/usp-controller-dart',
            MqttQos.atLeastOnce,
            any(),
          ),
        ).called(1);
      },
    );

    test('handleMessage handles unpacking errors gracefully', () async {
      final streamController =
          StreamController<List<MqttReceivedMessage<MqttMessage>>>.broadcast();
      when(
        () => mockMqttClient.updates,
      ).thenAnswer((_) => streamController.stream);

      // Connect and set up listener
      when(() => mockMqttClient.connect()).thenAnswer((_) async => null);
      when(() => mockMqttClient.connectionStatus).thenReturn(
        MqttClientConnectionStatus()..state = MqttConnectionState.connected,
      );
      when(() => mockMqttClient.onDisconnected = any()).thenReturn(null);
      await service.connect();

      // Create a malformed incoming message
      final malformedPayload = [1, 2, 3];

      final builder = MqttClientPayloadBuilder();
      builder.addBuffer(Uint8Buffer()..addAll(malformedPayload));

      final mqttMessage = MqttPublishMessage()
          .toTopic('usp/agent/proto::agent')
          .publishData(builder.payload!);

      streamController.add([
        MqttReceivedMessage('usp/agent/proto::agent', mqttMessage),
      ]);

      // Nothing should be published
      await Future.delayed(Duration(milliseconds: 100));
      verifyNever(() => mockMqttClient.publishMessage(any(), any(), any()));
    });
  });
}
