

import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'dart:async';
import 'package:usp_protocol_common/usp_protocol_common.dart';
import '../../infrastructure/adapter/usp_message_adapter.dart';
import 'package:typed_data/typed_data.dart';

class MqttMtpService {
  late final MqttServerClient _client;
  final UspMessageAdapter _messageAdapter;

  // Tools
  final UspRecordHelper _recordHelper = UspRecordHelper();
  final UspProtobufConverter _converter = UspProtobufConverter();

  // Settings
  final String _brokerHost;
  final int _brokerPort;
  final String _agentId;
  final String _agentTopic;
  final String _mqttClientId;

  MqttConnectionState? get connectionState => _client.connectionStatus?.state;
  int _retryCount = 0;
  final int _maxRetries = 3;
  final Duration _retryInterval = Duration(seconds: 5);

  // --- 1. Constructor ---
  MqttMtpService({
    required UspMessageAdapter adapter,
    required String agentId,
    String brokerHost = 'localhost',
    int brokerPort = 1883,
  }) : _messageAdapter = adapter,
       _agentId = agentId,
       _brokerHost = brokerHost,
       _brokerPort = brokerPort,
       _agentTopic = 'usp/agent/$agentId',
       _mqttClientId = 'sim-agent-${DateTime.now().millisecondsSinceEpoch}' {
    _initClient();
  }

  // --- 2. Initializer ---
  void _initClient() {
    _client = MqttServerClient.withPort(_brokerHost, _mqttClientId, _brokerPort)
      ..logging(on: false)
      ..keepAlivePeriod = 20
      ..onDisconnected = _onDisconnected;

    final connMess = MqttConnectMessage()
        .withClientIdentifier(_mqttClientId)
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);

    _client.connectionMessage = connMess;
  }

  /// Testing constructor, inject mock client
  MqttMtpService.internal(this._messageAdapter, this._client)
    : _agentId = "test-agent",
      _brokerHost = "localhost",
      _brokerPort = 1883,
      _agentTopic = "test/topic",
      _mqttClientId = "test-client" {
    _client.onDisconnected = _onDisconnected;
  }

  // --- 3. Start Process ---
  Future<void> start() async {
    await connect();
    if (connectionState == MqttConnectionState.connected) {
      await subscribe();
    }
  }

  Future<void> stop() async {
    _client.disconnect();
  }

  Future<void> connect() async {
    print('🔌 [MQTT] Connecting to broker at $_brokerHost:$_brokerPort...');

    while (_retryCount < _maxRetries) {
      try {
        await _client.connect();

        if (_client.connectionStatus?.state == MqttConnectionState.connected) {
          print('✅ [MQTT] Connected. (Agent ID: $_agentId)');
          _retryCount = 0;

          _client.updates!.listen(_handleMessage);
          return;
        }
      } catch (e) {
        print('⚠️ [MQTT] Connection exception: $e');
      }

      _retryCount++;
      print(
        '   Retrying in ${_retryInterval.inSeconds}s... ($_retryCount/$_maxRetries)',
      );
      await Future.delayed(_retryInterval);
    }

    print('❌ [MQTT] Failed to connect after $_maxRetries attempts.');
    _client.disconnect();
    throw Exception('MQTT connection failed after $_maxRetries attempts.');
  }

  void _onDisconnected() {
    print('🔌 [MQTT] Client disconnected.');

    if (_client.connectionStatus?.state != MqttConnectionState.disconnecting) {
      print('   🔄 Attempting auto-reconnect...');
      _retryCount = 0;
      connect();
    }
  }

  Future<void> subscribe() async {
    if (_client.connectionStatus?.state == MqttConnectionState.connected) {
      print('👂 [MQTT] Subscribing to topic: $_agentTopic');
      _client.subscribe(_agentTopic, MqttQos.atLeastOnce);
    } else {
      print('⚠️ [MQTT] Cannot subscribe, client is not connected.');
    }
  }

  // --- 4. Message Handler ---
  void _handleMessage(List<MqttReceivedMessage<MqttMessage>> event) async {
    final MqttPublishMessage receivedMessage =
        event[0].payload as MqttPublishMessage;
    final payloadBytes = receivedMessage.payload.message;
    final topic = event[0].topic;

    print('📩 [MQTT] RX on $topic (${payloadBytes.length} bytes)');

    try {
      // 1. Peek Header
      final Record incomingRecord = _recordHelper.peekHeader(
        payloadBytes,
      );
      final senderId = incomingRecord.fromId;

      // 2. Unwrap & Convert
      final Msg reqMsg = _recordHelper.unwrap(payloadBytes);
      final reqDto = _converter.fromProto(reqMsg);

      // 3. Execute Logic
      final resDto = await _messageAdapter.handleRequest(reqDto);

      // 4. Convert Response
      final resMsg = _converter.toProto(resDto, msgId: reqMsg.header.msgId);

      // 5. Wrap Response
      final resRecord = _recordHelper.wrap(
        resMsg,
        fromId: _agentId,
        toId: senderId,
      );

      // 6. Publish Response
      final replyTopic = 'usp/controller/${senderId.replaceAll(':', '_')}';
      final builder = MqttClientPayloadBuilder();

      builder.addBuffer(Uint8Buffer()..addAll(resRecord.writeToBuffer()));

      print('📤 [MQTT] TX to $replyTopic');
      _client.publishMessage(replyTopic, MqttQos.atLeastOnce, builder.payload!);
    } catch (e) {
      print('❌ [MQTT] Error handling message: $e');
    }
  }
}
