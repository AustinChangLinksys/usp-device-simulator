import 'package:test/test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:usp_protocol_common/usp_protocol_common.dart';
import 'package:usp_device2_simulator/domain/repositories/i_device_repository.dart';
import 'package:usp_device2_simulator/infrastructure/adapter/usp_message_adapter.dart';

// 1. Mock Repository
class MockDeviceRepository extends Mock implements IDeviceRepository {}

// 2. Fakes for Mocktail
class FakeUspPath extends Fake implements UspPath {}

class FakeUspValue extends Fake implements UspValue {}

void main() {
  group('UspMessageAdapter', () {
    late UspMessageAdapter adapter;
    late MockDeviceRepository mockRepo;

    setUpAll(() {
      registerFallbackValue(FakeUspPath());
      registerFallbackValue(FakeUspValue());
    });

    setUp(() {
      mockRepo = MockDeviceRepository();
      adapter = UspMessageAdapter(mockRepo);
    });

    // --- GET Tests ---
    test('handleRequest(Get) returns GetResponse on success', () async {
      // Arrange
      final path = UspPath.parse('Device.Time.LocalTimeZone');
      final value = UspValue('UTC', UspValueType.string);

      when(
        () => mockRepo.getParameterValue(any()),
      ).thenAnswer((_) async => {path: value});

      final req = UspGetRequest([path]);

      // Act
      final result = await adapter.handleRequest(req);

      // Assert
      expect(result, isA<UspGetResponse>());
      final resp = result as UspGetResponse;
      expect(resp.results[path], value);
    });

    test(
      'handleRequest(Get) handles repository errors gracefully (Partial Success)',
      () async {
        // Arrange: Repo throws error for one path
        when(
          () => mockRepo.getParameterValue(any()),
        ).thenThrow(UspException(7002, "Not found"));
        final req = UspGetRequest([UspPath.parse('Device.Bad.Path')]);

        // Act
        final result = await adapter.handleRequest(req);

        // Assert: Should return empty GetResponse, not throw
        expect(result, isA<UspGetResponse>());
        expect((result as UspGetResponse).results, isEmpty);
      },
    );

    // --- SET Tests ---
    test('handleRequest(Set) returns SetResponse on success', () async {
      // Arrange
      final path = UspPath.parse('Device.Time.Enable');
      final value = UspValue(true, UspValueType.boolean);
      when(
        () => mockRepo.setParameterValue(any(), any()),
      ).thenAnswer((_) async {});

      final req = UspSetRequest({path: value});

      // Act
      final result = await adapter.handleRequest(req);

      // Assert
      expect(result, isA<UspSetResponse>());
      expect((result as UspSetResponse).successPaths, contains(path));
    });

    test(
      'handleRequest(Set) handles partial failure when allowPartial=true',
      () async {
        // Arrange
        final path1 = UspPath.parse('Device.Good');
        final path2 = UspPath.parse('Device.Bad');

        when(
          () => mockRepo.setParameterValue(path1, any()),
        ).thenAnswer((_) async {});
        when(
          () => mockRepo.setParameterValue(path2, any()),
        ).thenThrow(UspException(7003, "Read Only"));

        final req = UspSetRequest({
          path1: UspValue(1, UspValueType.int),
          path2: UspValue(2, UspValueType.int),
        }, allowPartial: true);

        // Act
        final result = await adapter.handleRequest(req);

        // Assert
        final resp = result as UspSetResponse;
        expect(resp.successPaths, contains(path1));
        expect(resp.failurePaths, contains(path2));
      },
    );

    test(
      'handleRequest(Set) returns ErrorResponse when allowPartial=false and failure occurs',
      () async {
        // Arrange
        final path = UspPath.parse('Device.Bad');
        when(
          () => mockRepo.setParameterValue(any(), any()),
        ).thenThrow(UspException(7003, "Read Only"));

        final req = UspSetRequest({
          path: UspValue(1, UspValueType.int),
        }, allowPartial: false);

        // Act
        final result = await adapter.handleRequest(req);

        // Assert: Adapter catches the exception and returns ErrorResponse
        expect(result, isA<UspErrorResponse>());
        expect((result as UspErrorResponse).exception.errorCode, 7003);
      },
    );

    // --- ADD Tests ---
    test('handleRequest(Add) returns AddResponse', () async {
      // Arrange
      final parent = UspPath.parse('Device.WiFi.SSID');
      final newObjPath = UspPath.parse('Device.WiFi.SSID.1');

      when(
        () => mockRepo.addObject(
          any(),
          any(),
          instanceId: any(named: 'instanceId'),
        ),
      ).thenAnswer((_) async => newObjPath);
      // Mock parameter setting inside Add
      when(
        () => mockRepo.setParameterValue(any(), any()),
      ).thenAnswer((_) async {});

      final req = UspAddRequest([
        UspObjectCreation(
          parent,
          parameters: {'SSID': UspValue('MyWiFi', UspValueType.string)},
        ),
      ]);

      // Act
      final result = await adapter.handleRequest(req);

      // Assert
      expect(result, isA<UspAddResponse>());
      expect(
        (result as UspAddResponse).createdObjects.first.instantiatedPath,
        newObjPath,
      );
    });

    // --- DELETE Tests ---
    test('handleRequest(Delete) returns DeleteResponse', () async {
      // Arrange
      final path = UspPath.parse('Device.WiFi.SSID.1');
      when(() => mockRepo.deleteObject(any())).thenAnswer((_) async {});

      final req = UspDeleteRequest([path]);

      // Act
      final result = await adapter.handleRequest(req);

      // Assert
      expect(result, isA<UspDeleteResponse>());
      expect((result as UspDeleteResponse).deletedPaths, contains(path));
    });

    // --- General Error Tests ---
    test(
      'handleRequest returns ErrorResponse for unsupported message types',
      () async {
        // Arrange: Pass a Response DTO as a Request (Invalid scenario)
        final invalidReq = UspGetResponse({});

        // Act
        final result = await adapter.handleRequest(invalidReq);

        // Assert
        expect(result, isA<UspErrorResponse>());
        expect(
          (result as UspErrorResponse).exception.errorCode,
          7004,
        ); // Unsupported
      },
    );

    test('handleRequest catches unexpected exceptions', () async {
      // Arrange
      when(
        () => mockRepo.getParameterValue(any()),
      ).thenThrow(Exception("Unexpected Crash"));
      final req = UspGetRequest([UspPath.parse('Device.Crash')]);

      // Act
      final result = await adapter.handleRequest(req);

      // Assert
      expect(result, isA<UspErrorResponse>());
      expect(
        (result as UspErrorResponse).exception.errorCode,
        7000,
      ); // Internal Error
    });
  });
}
