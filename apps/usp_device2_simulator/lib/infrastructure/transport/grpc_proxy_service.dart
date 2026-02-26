import 'package:grpc/grpc.dart' as grpc;
import 'package:usp_device2_simulator/infrastructure/adapter/usp_message_adapter.dart';
import 'package:usp_protocol_common/usp_protocol_common.dart';

class GrpcProxyService extends UspTransportServiceBase {
  final UspRecordHelper _recordHelper;
  final UspMessageAdapter _uspMessageAdapter;
  final String _agentId;
  final UspProtobufConverter _uspProtobufConverter;

  GrpcProxyService(
    this._uspMessageAdapter,
    this._agentId, {
    UspRecordHelper? recordHelper,
  }) : _recordHelper =
           recordHelper ?? UspRecordHelper(), // Supports test injection.
       _uspProtobufConverter = UspProtobufConverter();

  @override
  Future<UspTransportResponse> sendUspMessage(
    grpc.ServiceCall call,
    UspTransportRequest request,
  ) async {
    // 1. Basic validation.
    if (request.uspRecordPayload.isEmpty) {
      throw grpc.GrpcError.invalidArgument(
        'USP Transport Request usp_record_payload cannot be empty.',
      );
    }

    // 2. Parse Header (Peek).
    Record recordHeader;
    try {
      recordHeader = _recordHelper.peekHeader(request.uspRecordPayload);
    } catch (e) {
      throw grpc.GrpcError.invalidArgument(
        'Failed to peek USP Record header: $e',
      );
    }
    final senderId = recordHeader.fromId;

    // 3. Unwrap and Execute (Wrap in Try-Catch).
    try {
      // Unwrap Msg
      final Msg uspMsg = _recordHelper.unwrap(request.uspRecordPayload);

      // Moved fromProto into try block and handle potential exception.
      final requestDto = _uspProtobufConverter.fromProto(uspMsg);

      // Adapter Execution
      final responseDto = await _uspMessageAdapter.handleRequest(requestDto);

      // Convert response DTO back to Msg
      final responseMsg = _uspProtobufConverter.toProto(
        responseDto,
        msgId: uspMsg.header.msgId,
      );

      // Wrap in USP Record
      final Record responseRecord = _recordHelper.wrap(
        responseMsg,
        fromId: _agentId,
        toId: senderId,
      );

      // Return wrapped USP Record
      return UspTransportResponse()
        ..uspRecordResponse = responseRecord.writeToBuffer();
    } on UspException catch (e) {
      // Refined error handling

      // Case A: Client-side data issues (malformed, incorrect parameters, unsupported operation).
      if (e.errorCode == 7003 || e.errorCode == 7004 || e.errorCode == 7005) {
        throw grpc.GrpcError.invalidArgument(
          'USP Validation Error: ${e.message} (Code: ${e.errorCode})',
        );
      }

      // Case B: Server internal issues (e.g., 7000, 7002).
      // Although 7002 is Request Denied, at the gRPC layer it's usually treated as an execution failure and can be mapped to PERMISSION_DENIED.
      // Here it's simply categorized as Internal or Unknown.
      throw grpc.GrpcError.internal(
        'USP Execution Failed: ${e.message} (Code: ${e.errorCode})',
      );
    } catch (e) {
      throw grpc.GrpcError.internal(
        'Internal server error during USP message processing: $e',
      );
    }
  }
}
