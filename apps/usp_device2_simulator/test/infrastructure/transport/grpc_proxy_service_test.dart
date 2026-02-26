import 'package:grpc/grpc.dart' as grpc;
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:usp_protocol_common/usp_protocol_common.dart';
import 'package:usp_protocol_common/src/generated/usp_record.pb.dart'
    as pb_record;
import 'package:usp_protocol_common/src/generated/usp_msg.pb.dart' as pb_msg;
import 'package:usp_device2_simulator/infrastructure/adapter/usp_message_adapter.dart';
import 'package:usp_device2_simulator/infrastructure/transport/grpc_proxy_service.dart';

// Mocks
class MockUspMessageAdapter extends Mock implements UspMessageAdapter {}

class MockUspRecordHelper extends Mock implements UspRecordHelper {}

class MockServiceCall extends Mock implements grpc.ServiceCall {}

// Fakes
class FakeUspMessage extends Fake implements UspMessage {}

class FakeMsg extends Fake implements pb_msg.Msg {}

class FakeRecord extends Fake implements pb_record.Record {}

void main() {
  late GrpcProxyService service;
  late MockUspMessageAdapter mockAdapter;
  late MockUspRecordHelper mockRecordHelper;
  late MockServiceCall mockServiceCall;
  const String agentId = 'proto::agent'; // Consistent ID

  setUpAll(() {
    registerFallbackValue(FakeUspMessage());
    registerFallbackValue(FakeMsg());
    registerFallbackValue(FakeRecord());
  });

  setUp(() {
    mockAdapter = MockUspMessageAdapter();
    mockRecordHelper = MockUspRecordHelper();
    mockServiceCall = MockServiceCall();

    service = GrpcProxyService(
      mockAdapter,
      agentId,
      recordHelper: mockRecordHelper,
    );
  });

  group('sendUspMessage - Successful Scenarios', () {
    test('should process a valid USP request and return a response', () async {
      // Arrange
      final uspMsg = pb_msg.Msg()
        ..header = (pb_msg.Header()..msgId = 'test-msg-id')
        ..body = (pb_msg.Body()
          ..request = (pb_msg.Request()
            ..get = (pb_msg.Get()..paramPaths.add('Device.Time.'))));
      final uspRecord = pb_record.Record()
        ..fromId = 'controller-1'
        ..toId = agentId
        ..noSessionContext = (pb_record.NoSessionContextRecord()
          ..payload = uspMsg.writeToBuffer());

      final requestPayload = uspRecord.writeToBuffer();
      final request = UspTransportRequest()..uspRecordPayload = requestPayload;

      final responseUspMsg = pb_msg.Msg()
        ..header = (pb_msg.Header()..msgId = 'test-msg-id')
        ..body = (pb_msg.Body()
          ..response = (pb_msg.Response()..getResp = pb_msg.GetResp()));
      final responseUspRecord = pb_record.Record()
        ..fromId = agentId
        ..toId = 'controller-1'
        ..noSessionContext = (pb_record.NoSessionContextRecord()
          ..payload = responseUspMsg.writeToBuffer());

      final converter = UspProtobufConverter();
      final responseDto = converter.fromProto(responseUspMsg);

      // Mock behavior
      when(() => mockRecordHelper.peekHeader(any())).thenReturn(uspRecord);
      when(() => mockRecordHelper.unwrap(any())).thenReturn(uspMsg);
      when(
        () => mockRecordHelper.wrap(
          any(), // Msg
          fromId: any(named: 'fromId'),
          toId: any(named: 'toId'),
        ),
      ).thenReturn(responseUspRecord);

      when(
        () => mockAdapter.handleRequest(any()),
      ).thenAnswer((_) async => responseDto);

      // Act
      final response = await service.sendUspMessage(mockServiceCall, request);

      // Assert
      expect(response.uspRecordResponse, responseUspRecord.writeToBuffer());

      verify(() => mockRecordHelper.peekHeader(any())).called(1);
      verify(() => mockRecordHelper.unwrap(any())).called(1);
      verify(() => mockAdapter.handleRequest(any())).called(1);
      verify(
        () =>
            mockRecordHelper.wrap(any(), fromId: agentId, toId: 'controller-1'),
      ).called(1);
    });
  });

  group('sendUspMessage - Error Scenarios', () {
    test(
      'should throw GrpcError.invalidArgument if payload is empty',
      () async {
        // Arrange
        final request = UspTransportRequest()..uspRecordPayload = [];

        // Act & Assert
        expect(
          () => service.sendUspMessage(mockServiceCall, request),
          throwsA(
            isA<grpc.GrpcError>().having(
              (e) => e.code,
              'code',
              grpc.StatusCode.invalidArgument,
            ),
          ),
        );
      },
    );

    test(
      'should throw GrpcError.invalidArgument if peekHeader fails (Malformed Header)',
      () async {
        // Arrange
        final malformedPayload = [1, 2, 3];
        final request = UspTransportRequest()
          ..uspRecordPayload = malformedPayload;

        when(
          () => mockRecordHelper.peekHeader(any()),
        ).thenThrow(Exception('Malformed record header'));

        // Act & Assert
        expect(
          () => service.sendUspMessage(mockServiceCall, request),
          throwsA(
            isA<grpc.GrpcError>().having(
              (e) => e.code,
              'code',
              grpc.StatusCode.invalidArgument,
            ),
          ),
        );
      },
    );

    test(
      'should throw GrpcError.internal if Adapter throws UspException',
      () async {
        // Arrange
        final validRecord = pb_record.Record()..fromId = 'controller-1';
        final payload = validRecord.writeToBuffer();
        final request = UspTransportRequest()..uspRecordPayload = payload;

        when(() => mockRecordHelper.peekHeader(any())).thenReturn(validRecord);
        when(
          () => mockRecordHelper.unwrap(any()),
        ).thenReturn(pb_msg.Msg()); // Return empty msg

        when(
          () => mockAdapter.handleRequest(any()),
        ).thenThrow(UspException(7000, 'Test Adapter Error'));

        // Act & Assert
        expect(
          () => service.sendUspMessage(mockServiceCall, request),
          throwsA(
            isA<grpc.GrpcError>().having(
              (e) => e.code,
              'code',
              grpc.StatusCode.invalidArgument,
            ),
          ),
        );
      },
    );

    test(
      'should throw GrpcError.invalidArgument if Adapter throws UspException(7004)',
      () async {
        final validRecord = pb_record.Record()..fromId = 'controller-1';
        final payload = validRecord.writeToBuffer();
        final request = UspTransportRequest()..uspRecordPayload = payload;
        // Simulate USP 7004 (Unsupported Message)
        when(
          () => mockAdapter.handleRequest(any()),
        ).thenThrow(UspException(7004, 'Msg Not Supported'));

        // Act & Assert
        expect(
          () => service.sendUspMessage(mockServiceCall, request),
          throwsA(
            isA<grpc.GrpcError>().having(
              (e) => e.code,
              'code',
              grpc.StatusCode.invalidArgument,
            ),
          ),
        );
      },
    );

    test(
      'should throw GrpcError.internal if Adapter throws UspException(7000)',
      () async {
        // Arrange
        final validRecord = pb_record.Record()..fromId = 'controller-1';
        final payload = validRecord.writeToBuffer();
        final request = UspTransportRequest()..uspRecordPayload = payload;

        // Simulate a valid Msg (e.g. Get Request), so the Converter can pass
        final validMsg = pb_msg.Msg()
          ..header = (pb_msg.Header()..msgId = '123')
          ..body = (pb_msg.Body()
            ..request = (pb_msg.Request()..get = pb_msg.Get()));

        when(() => mockRecordHelper.peekHeader(any())).thenReturn(validRecord);

        // Let unwrap return this valid Msg
        when(() => mockRecordHelper.unwrap(any())).thenReturn(validMsg);

        // Simulate Adapter throwing 7000 (this is what we want to test)
        when(
          () => mockAdapter.handleRequest(any()),
        ).thenThrow(UspException(7000, 'Internal Crash'));

        // Act & Assert
        expect(
          () => service.sendUspMessage(mockServiceCall, request),
          throwsA(
            isA<grpc.GrpcError>().having(
              (e) => e.code,
              'code',
              grpc.StatusCode.internal,
            ),
          ),
        );
      },
    );

    test(
      'should throw GrpcError.internal if Adapter throws unexpected Generic Exception',
      () async {
        // Arrange
        final validRecord = pb_record.Record()..fromId = 'controller-1';
        final payload = validRecord.writeToBuffer();
        final request = UspTransportRequest()..uspRecordPayload = payload;

        when(() => mockRecordHelper.peekHeader(any())).thenReturn(validRecord);
        when(() => mockRecordHelper.unwrap(any())).thenReturn(
          pb_msg.Msg()
            ..body = (pb_msg.Body()
              ..request = (pb_msg.Request()..get = pb_msg.Get())),
        );

        // [Simulate] Adapter throws Generic Exception
        when(
          () => mockAdapter.handleRequest(any()),
        ).thenThrow(Exception('Unexpected DB Crash'));

        // Act & Assert
        expect(
          () => service.sendUspMessage(mockServiceCall, request),
          throwsA(
            isA<grpc.GrpcError>()
                .having((e) => e.code, 'code', grpc.StatusCode.internal)
                .having(
                  (e) => e.message,
                  'message',
                  contains('Unexpected DB Crash'),
                ),
          ),
        );
      },
    );
    test(
      'should throw GrpcError.invalidArgument if Adapter throws UspException(7003)',
      () async {

        final validRecord = pb_record.Record()..fromId = 'controller-1';
        final payload = validRecord.writeToBuffer();
        final request = UspTransportRequest()..uspRecordPayload = payload;

        when(() => mockRecordHelper.peekHeader(any())).thenReturn(validRecord);
        when(() => mockRecordHelper.unwrap(any())).thenReturn(
          pb_msg.Msg()
            ..body = (pb_msg.Body()
              ..request = (pb_msg.Request()..set = pb_msg.Set())),
        );

        // [Simulate] Adapter throws UspException(7003)
        when(
          () => mockAdapter.handleRequest(any()),
        ).thenThrow(UspException(7003, 'Invalid Param'));

        // Act & Assert
        expect(
          () => service.sendUspMessage(mockServiceCall, request),
          throwsA(
            isA<grpc.GrpcError>().having(
              (e) => e.code,
              'code',
              grpc.StatusCode.invalidArgument,
            ),
          ),
        );
      },
    );
  });
}
