import 'package:test/test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:usp_device2_simulator/domain/entities/device_tree.dart';
import 'package:usp_device2_simulator/infrastructure/persistence/i_persistence_service.dart';
import 'package:usp_device2_simulator/infrastructure/repositories/device_repository_impl.dart';
import 'package:usp_device2_simulator/infrastructure/schema/i_schema_loader.dart';

// Mocks
class MockPersistenceService extends Mock implements IPersistenceService {}

class MockSchemaLoader extends Mock implements ISchemaLoader {}

class MockDeviceTree extends Mock implements DeviceTree {}

void main() {
  group('DeviceRepositoryImpl.create', () {
    late MockPersistenceService mockPersistenceService;
    late MockSchemaLoader mockSchemaLoader;
    const schemaFilePath = 'test/data/router_scheme.xml';

    setUp(() {
      mockPersistenceService = MockPersistenceService();
      mockSchemaLoader = MockSchemaLoader();
    });

    test('should load from persistence when data is available', () async {
      // Arrange
      final mockDeviceTree = MockDeviceTree();
      when(
        () => mockPersistenceService.load(),
      ).thenAnswer((_) async => mockDeviceTree);

      // Act
      final repository = await DeviceRepositoryImpl.create(
        mockPersistenceService,
        mockSchemaLoader,
        schemaFilePath,
      );

      // Assert
      verify(() => mockPersistenceService.load()).called(1);
      verifyNever(() => mockSchemaLoader.loadSchema(any()));
      expect(repository.getDeviceTree(), mockDeviceTree);
    });

    test('should load from schema when persistence is empty', () async {
      // Arrange
      final mockDeviceTree = MockDeviceTree();
      when(() => mockPersistenceService.load()).thenAnswer((_) async => null);
      when(
        () => mockSchemaLoader.loadSchema(any()),
      ).thenAnswer((_) async => mockDeviceTree);

      // Act
      final repository = await DeviceRepositoryImpl.create(
        mockPersistenceService,
        mockSchemaLoader,
        schemaFilePath,
      );

      // Assert
      verify(() => mockPersistenceService.load()).called(1);
      verify(() => mockSchemaLoader.loadSchema(any())).called(1);
      expect(repository.getDeviceTree(), mockDeviceTree);
    });
  });
}
