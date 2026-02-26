import 'package:test/test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:usp_protocol_common/usp_protocol_common.dart';
import 'package:usp_device2_simulator/application/usecases/add_object_usecase.dart';
import 'package:usp_device2_simulator/infrastructure/provisioning/smart_provisioner.dart';

// 1. Define Mock Class
// Manually mock to avoid extra codegen setup
class MockAddObjectUseCase extends Mock implements AddObjectUseCase {}

// 2. Define Fake for UspPath (Required by mocktail if used with any())
class FakeUspPath extends Fake implements UspPath {
  final String _mockPath;

  FakeUspPath([this._mockPath = '']);

  @override
  String get fullPath => _mockPath;

  @override
  UspPath? get parent => _mockPath.isEmpty ? null : FakeUspPath(_mockPath.substring(0, _mockPath.lastIndexOf('.')));

  @override
  List<String> get segments => _mockPath.isEmpty ? [] : _mockPath.split('.');

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UspPath && other.fullPath == fullPath;
  }

  @override
  int get hashCode => fullPath.hashCode;
}

void main() {
  group('SmartProvisioner (using mocktail)', () {
    late SmartProvisioner provisioner;
    late MockAddObjectUseCase mockUseCase;

    setUpAll(() {
      // Register Fallback Value to prevent any() errors
      registerFallbackValue(FakeUspPath());
    });

    setUp(() {
      mockUseCase = MockAddObjectUseCase();
      provisioner = SmartProvisioner(mockUseCase);

      // Default Stub: Make execute return a successful Future by default
      // Simulate execute returning the newly created path
      when(() => mockUseCase.execute(
            any(),
            any(),
            instanceId: any(named: 'instanceId'),
          )).thenAnswer((invocation) async {
        final parent = invocation.positionalArguments[0] as UspPath;
        final id = invocation.namedArguments[#instanceId] as int;
        return UspPath.parse('${parent.fullPath}.$id');
      });
    });

    test('Scenario 1: Should ignore paths without instance IDs (Static paths)', () async {
      // Arrange
      final config = {
        'Device.DeviceInfo.Manufacturer': 'DartSim',
        'Device.Time.LocalTimeZone': 'UTC',
      };

      // Act
      await provisioner.provision(config);

      // Assert
      verifyNever(() => mockUseCase.execute(any(), any(), instanceId: any(named: 'instanceId')));
    });

    test('Scenario 2: Should create single instance from config key', () async {
      // Arrange
      final config = {
        'Device.WiFi.Radio.1.Channel': 6,
      };

      // Act
      await provisioner.provision(config);

      // Assert
      // Verify call: execute(UspPath('Device.WiFi.Radio'), 'Radio', instanceId: 1)
      verify(() => mockUseCase.execute(
            UspPath.parse('Device.WiFi.Radio'), // Parent (Table)
            'Ignored',                          // Name (Derived from path)
            instanceId: 1,
          )).called(1);
    });

    test('Scenario 3: Should deduplicate calls for the same instance', () async {
      // Arrange: 3 keys all pointing to Radio.1
      final config = {
        'Device.WiFi.Radio.1.Channel': 6,
        'Device.WiFi.Radio.1.Enable': true,
        'Device.WiFi.Radio.1.Status': 'Up',
      };

      // Act
      await provisioner.provision(config);

      // Assert
      // Verify AddObject is called only once
      verify(() => mockUseCase.execute(any(), any(), instanceId: 1)).called(1);
    });

    test('Scenario 4: Should create instances in correct order (Parent before Child)', () async {
      // Arrange: Nested instances (Interface.1 -> IPv4Address.1)
      // Intentionally place child first to test sorting logic
      final config = {
        'Device.IP.Interface.1.IPv4Address.1.IPAddress': '192.168.1.1',
        'Device.IP.Interface.1.Enable': true,
      };

      // Act
      await provisioner.provision(config);

      // Assert
      // Use verifyInOrder to ensure call sequence
      verifyInOrder([
        // 1. Create Parent first (Interface.1)
        () => mockUseCase.execute(
              UspPath.parse('Device.IP.Interface'),
              any(),
              instanceId: 1,
            ),
        // 2. Create Child second (IPv4Address.1)
        () => mockUseCase.execute(
              UspPath.parse('Device.IP.Interface.1.IPv4Address'),
              any(),
              instanceId: 1,
            ),
      ]);
    });

    test('Scenario 5: Should handle multiple instances at same level', () async {
      // Arrange
      final config = {
        'Device.WiFi.Radio.1.Channel': 1,
        'Device.WiFi.Radio.2.Channel': 6,
        'Device.WiFi.Radio.10.Channel': 11,
      };

      // Act
      await provisioner.provision(config);

      // Assert
      verify(() => mockUseCase.execute(any(), any(), instanceId: 1)).called(1);
      verify(() => mockUseCase.execute(any(), any(), instanceId: 2)).called(1);
      verify(() => mockUseCase.execute(any(), any(), instanceId: 10)).called(1);
    });

    test('Scenario 6: Resilience - Should continue even if one AddObject fails', () async {
      // Arrange
      // Mock exception for Instance 999
      when(() => mockUseCase.execute(
            any(),
            any(),
            instanceId: 999,
          )).thenThrow(UspException(7002, "Mock Error"));

      final config = {
        'Device.BadTable.999.Param': 'Value', // Will fail
        'Device.GoodTable.1.Param': 'Value',  // Should succeed
      };

      // Act
      // This should NOT throw an exception (provision should catch it)
      await provisioner.provision(config);

      // Assert
      // 1. Verify the failed one was called
      verify(() => mockUseCase.execute(any(), any(), instanceId: 999)).called(1);
      
      // 2. Verify the successful one was still executed (not interrupted by previous failure)
      verify(() => mockUseCase.execute(
            UspPath.parse('Device.GoodTable'), 
            any(), 
            instanceId: 1
          )).called(1);
    });

    test('Scenario 7: Edge case - Empty config', () async {
      // Act
      await provisioner.provision({});

      // Assert
      verifyZeroInteractions(mockUseCase);
    });
  });
}