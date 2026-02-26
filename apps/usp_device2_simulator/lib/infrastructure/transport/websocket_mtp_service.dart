import 'dart:io';
import 'package:usp_protocol_common/usp_protocol_common.dart';
import '../adapter/usp_message_adapter.dart';

class WebSocketMtpService {
  final UspMessageAdapter _adapter;

  final UspRecordHelper _recordHelper = UspRecordHelper();
  final UspProtobufConverter _converter = UspProtobufConverter();

  HttpServer? _server;

  WebSocketMtpService(this._adapter);

  Future<void> start({int port = 8080}) async {
    try {
      _server = await HttpServer.bind(InternetAddress.anyIPv4, port);
      print('🚀 WebSocket Server listening on ws://0.0.0.0:$port');

      _server!.listen((HttpRequest request) {
        if (WebSocketTransformer.isUpgradeRequest(request)) {
          WebSocketTransformer.upgrade(request).then(_handleConnection);
        } else {
          request.response
            ..statusCode = HttpStatus.forbidden
            ..close();
        }
      });
    } catch (e) {
      print('❌ Server failed to start: $e');
      rethrow;
    }
  }

  void _handleConnection(WebSocket socket) {
    print('Client connected: ${socket.hashCode}');

    socket.listen(
      (data) async {
        if (data is List<int>) {
          try {
            // 1. [Header Inspection] Peek at the record header to identify the sender.
            // We use peekHeader (or parsing the Record directly) to get the 'fromId'.
            // This ensures we reply to the specific controller that sent the request.
            final incomingRecord = _recordHelper.peekHeader(data);
            final senderId = incomingRecord.fromId;



            // 2. [Unpack] Unwrap the Record to extract the inner USP Message (Payload).
            // This validates the record structure and security (e.g., ensures payload exists).
            final reqMsg = _recordHelper.unwrap(data);

            // 3. [Decode] Convert the Protobuf Message to a Domain DTO.
            final reqDto = _converter.fromProto(reqMsg);
            print("📩 RX: ${reqDto.runtimeType} from '$senderId'");

            // 4. [Execute] Pass the DTO to the Adapter to execute business logic.
            // The adapter interacts with the DeviceRepository and returns a Response DTO.
            final resDto = await _adapter.handleRequest(reqDto);

            // 5. [Encode] Convert the Response DTO back to a Protobuf Message.
            // We must use the same 'msgId' from the request to maintain the transaction context.
            final resMsg = _converter.toProto(
              resDto,
              msgId: reqMsg.header.msgId,
            );

            // 6. [Pack] Wrap the Response Message into a new USP Record.
            // Crucial: Set 'toId' to the 'senderId' we extracted in Step 1.
            final resRecord = _recordHelper.wrap(
              resMsg,
              fromId: "proto::simulator", // The ID of this Agent (Server)
              toId: senderId, // Reply back to the original Sender (Client)
            );

            // 7. [Send] Serialize the Record to bytes and send over WebSocket.
            socket.add(resRecord.writeToBuffer());
            print("📤 TX: ${resDto.runtimeType} to '$senderId'");
          } catch (e) {
            print('⚠️ Error processing packet: $e');
            // Note: In a production environment, you might want to send a USP Error Record back
            // if the header is parseable but the payload is invalid.
          }
        }
      },
      onDone: () => print('Client disconnected: ${socket.hashCode}'),
      onError: (e) => print('WebSocket error: $e'),
    );
  }

  Future<void> stop() async {
    await _server?.close();
  }
}
