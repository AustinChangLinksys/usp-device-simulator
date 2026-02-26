import 'package:test/test.dart';
import 'package:usp_device2_simulator/domain/entities/device_tree.dart';
import 'package:usp_device2_simulator/domain/entities/usp_object.dart';
import 'package:usp_device2_simulator/domain/entities/usp_parameter.dart';
import 'package:usp_protocol_common/usp_protocol_common.dart';
import 'package:usp_device2_simulator/infrastructure/repositories/device_repository_impl.dart';
import '../../mocks.dart';
import 'package:mocktail/mocktail.dart';

import 'dart:io'; // For File and FileSystemException

void main() {
  setUpAll(() {
    registerDeviceTreeFallback(); // Register fallback for DeviceTree
  });

  group('DeviceRepositoryImpl', () {
    late DeviceRepositoryImpl repository;
    late DeviceTree deviceTree;
    late MockPersistenceService mockPersistenceService; // Declare mock

    setUp(() {
      mockPersistenceService = MockPersistenceService(); // Initialize mock
      // Stub the save method to do nothing
      when(() => mockPersistenceService.save(any())).thenAnswer((_) async {});
      when(() => mockPersistenceService.load()).thenAnswer((_) async => null);

      final writableParam = UspParameter<String>(
        path: UspPath.parse('Device.Test.WritableParam'),
        value: UspValue('initial_value', UspValueType.string),
        isWritable: true,
      );

      final readOnlyParam = UspParameter<String>(
        path: UspPath.parse('Device.Test.ReadOnlyParam'),
        value: UspValue('readonly_value', UspValueType.string),
        isWritable: false,
      );

      final testObj = UspObject(
        path: UspPath.parse('Device.Test.'),
        children: {
          'WritableParam': writableParam,
          'ReadOnlyParam': readOnlyParam,
        },
      );

      final root = UspObject(
        path: UspPath.parse('Device.'),
        children: {'Test': testObj},
      );

      deviceTree = DeviceTree(root: root);
      repository = DeviceRepositoryImpl(
        deviceTree,
        mockPersistenceService,
      ); // Pass mock
    });

    test(
      'getParameterValue should return value for existing parameter',
      () async {
        // Act
        final result = await repository.getParameterValue(
          UspPath.parse('Device.Test.WritableParam'),
        );

        // Assert
        expect(result.length, 1);
        expect(result.values.first.value, 'initial_value');
      },
    );

    test(
      'getParameterValue should throw UspException for non-existing parameter',
      () {
        // Act & Assert
        expect(
          () async => await repository.getParameterValue(
            UspPath.parse('Device.Test.NonExistent'),
          ),
          throwsA(isA<UspException>()),
        );
      },
    );

    test(
      'setParameterValue should update value for writable parameter',
      () async {
        // Arrange
        final path = UspPath.parse('Device.Test.WritableParam');
        final newValue = UspValue('new_value', UspValueType.string);

        // Act
        await repository.setParameterValue(path, newValue);
        final result = await repository.getParameterValue(path);

        // Assert
        expect(result.length, 1);
        expect(result.values.first.value, 'new_value');
      },
    );

    test(
      'setParameterValue should throw UspException for read-only parameter',
      () {
        // Arrange
        final path = UspPath.parse('Device.Test.ReadOnlyParam');
        final newValue = UspValue('new_value', UspValueType.string);

        // Act & Assert
        expect(
          () async => await repository.setParameterValue(path, newValue),
          throwsA(isA<UspException>()),
        );
      },
    );

    group('create factory method', () {
      late MockPersistenceService mockPersistence;
      late MockSchemaLoader mockSchemaLoader;
      late Directory tempDir;
      late String testXmlContent;
      late DeviceTree loadedDeviceTree;

      setUp(() {
        mockPersistence = MockPersistenceService();
        mockSchemaLoader = MockSchemaLoader();
        tempDir = Directory.systemTemp.createTempSync('repo_create_test');
        testXmlContent = '<schema></schema>';

        final tempWritableParam = UspParameter<String>(
          path: UspPath.parse('Device.Temp.Param'),
          value: UspValue('temp_value', UspValueType.string),
          isWritable: true,
        );
        final tempTestObj = UspObject(
          path: UspPath.parse('Device.Temp.'),
          children: {'Param': tempWritableParam},
        );
        loadedDeviceTree = DeviceTree(
          root: UspObject(
            path: UspPath.parse('Device.'),
            children: {'Temp': tempTestObj},
          ),
        );
      });

      tearDown(() {
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      });

      test('should load from persistence if data exists', () async {
        // Arrange
        when(
          () => mockPersistence.load(),
        ).thenAnswer((_) async => loadedDeviceTree);
        // Act
        final repo = await DeviceRepositoryImpl.create(
          mockPersistence,
          mockSchemaLoader,
          'any_path.xml',
        );
        // Assert
        expect(repo.getDeviceTree(), loadedDeviceTree);
        verify(() => mockPersistence.load()).called(1);
        verifyNever(
          () => mockSchemaLoader.loadSchema(any()),
        ); // Schema loader should not be called
      });

      test('should load from schema if persistence is empty', () async {
        // Arrange
        when(
          () => mockPersistence.load(),
        ).thenAnswer((_) async => null); // Persistence empty
        final tempSchemaFile = File('${tempDir.path}/temp_schema.xml');
        await tempSchemaFile.writeAsString(
          testXmlContent,
        ); // Create a real temporary file

        when(
          () => mockSchemaLoader.loadSchema(testXmlContent),
        ).thenAnswer((_) async => loadedDeviceTree);

        // Act
        final repo = await DeviceRepositoryImpl.create(
          mockPersistence,
          mockSchemaLoader,
          tempSchemaFile.path,
        );

        // Assert
        expect(repo.getDeviceTree(), loadedDeviceTree);
        verify(() => mockPersistence.load()).called(1);
        verify(() => mockSchemaLoader.loadSchema(testXmlContent)).called(1);
      });

      test('should throw FileSystemException if schema file not found', () async {
        // Arrange
        when(
          () => mockPersistence.load(),
        ).thenAnswer((_) async => null); // Persistence empty
        final nonExistentSchemaPath =
            '${tempDir.path}/non_existent_schema.xml'; // Path to a non-existent file

        // Act & Assert
        expect(
          () async => await DeviceRepositoryImpl.create(
            mockPersistence,
            mockSchemaLoader,
            nonExistentSchemaPath,
          ),
          throwsA(
            isA<FileSystemException>(),
          ), // Expecting FileSystemException for file not found
        );
      });
    });
    group('addObject', () {
      late DeviceRepositoryImpl repository;
      late DeviceTree deviceTree;
      late MockPersistenceService mockPersistenceService;

      setUp(() {
        mockPersistenceService = MockPersistenceService();
        when(() => mockPersistenceService.save(any())).thenAnswer((_) async {});

        final templateParam = UspParameter<String>(
          path: UspPath.parse('Device.MultiInstanceObject.{i}.Param'),
          value: UspValue('template_value', UspValueType.string),
          isWritable: true,
        );

        final templateObject = UspObject(
          path: UspPath.parse('Device.MultiInstanceObject.{i}.'),
          children: {'Param': templateParam},
          isMultiInstance: true,
        );

        final multiInstanceObjectTable = UspObject(
          path: UspPath.parse('Device.MultiInstanceObject.'),
          children: {'{i}': templateObject},
          isMultiInstance: false,
        );

        final root = UspObject(
          path: UspPath.parse('Device.'),
          children: {'MultiInstanceObject': multiInstanceObjectTable},
        );

        deviceTree = DeviceTree(root: root);
        repository = DeviceRepositoryImpl(deviceTree, mockPersistenceService);
      });

      test('should throw UspException if parent object not found', () async {
        final nonExistentParentPath = UspPath.parse(
          'Device.NonExistentObject.',
        );
        expect(
          () async =>
              await repository.addObject(nonExistentParentPath, 'Template'),
          throwsA(
            isA<UspException>().having((e) => e.errorCode, 'errorCode', 7002),
          ),
        );
      });

      test('should throw UspException if template node is null', () async {
        // Create a parent without a {i} template
        final parentPath = UspPath.parse('Device.SingleInstanceObject.');
        final singleInstanceObject = UspObject(
          path: parentPath,
          children: {}, // No {i} template
        );
        deviceTree = DeviceTree(root: singleInstanceObject);
        repository = DeviceRepositoryImpl(deviceTree, mockPersistenceService);

        expect(
          () async => await repository.addObject(parentPath, 'Template'),
          throwsA(
            isA<UspException>().having((e) => e.errorCode, 'errorCode', 7002),
          ),
        );
      });

      test(
        'should throw UspException if template node is not UspObject',
        () async {
          // Create a parent with a {i} template that is a Parameter
          final parentPath = UspPath.parse('Device.InvalidTemplateObject.');
          final invalidTemplateParam = UspParameter<String>(
            path: UspPath.parse('Device.InvalidTemplateObject.{i}'),
            value: UspValue('value', UspValueType.string),
          );
          final invalidTemplateTable = UspObject(
            path: parentPath,
            children: {'{i}': invalidTemplateParam},
          );
          // Create a root Device object that contains the invalidTemplateTable
          deviceTree = DeviceTree(
            root: UspObject(
              path: UspPath.parse('Device.'),
              children: {'InvalidTemplateObject': invalidTemplateTable},
            ),
          );
          repository = DeviceRepositoryImpl(deviceTree, mockPersistenceService);

          expect(
            () async => await repository.addObject(parentPath, 'Template'),
            throwsA(
              isA<UspException>().having((e) => e.errorCode, 'errorCode', 7003),
            ),
          );
        },
      );

      test('should successfully add a new multi-instance object', () async {
        final parentPath = UspPath.parse('Device.MultiInstanceObject.');
        final newObjectPath = await repository.addObject(
          parentPath,
          'Template',
          instanceId: 1,
        );

        expect(newObjectPath.fullPath, 'Device.MultiInstanceObject.1');
        final addedObject = repository
            .getDeviceTree()
            .root
            .getChild('MultiInstanceObject')!
            .getChild('1');
        expect(addedObject, isNotNull);
        expect(addedObject, isA<UspObject>());
        expect(
          (addedObject as UspObject).getChild('Param'),
          isA<UspParameter>(),
        );
      });
    });
    group('deleteObject', () {
      late DeviceRepositoryImpl repository;
      late DeviceTree deviceTree;
      late MockPersistenceService mockPersistenceService;

      setUp(() {
        mockPersistenceService = MockPersistenceService();
        when(() => mockPersistenceService.save(any())).thenAnswer((_) async {});

        final multiInstanceObject1 = UspObject(
          path: UspPath.parse('Device.MultiInstanceObject.1.'),
          isMultiInstance: true,
        );
        final multiInstanceObject2 = UspObject(
          path: UspPath.parse('Device.MultiInstanceObject.2.'),
          isMultiInstance: true,
        );

        final multiInstanceObjectTable = UspObject(
          path: UspPath.parse('Device.MultiInstanceObject.'),
          children: {'1': multiInstanceObject1, '2': multiInstanceObject2},
        );

        final root = UspObject(
          path: UspPath.parse('Device.'),
          children: {'MultiInstanceObject': multiInstanceObjectTable},
        );

        deviceTree = DeviceTree(root: root);
        repository = DeviceRepositoryImpl(deviceTree, mockPersistenceService);
      });

      test(
        'should throw UspException when trying to delete the root object',
        () async {
          final rootPath = UspPath.parse('Device.');
          expect(
            () async => await repository.deleteObject(rootPath),
            throwsA(
              isA<UspException>().having((e) => e.errorCode, 'errorCode', 7006),
            ),
          );
        },
      );

      test(
        'should throw UspException if object not found for deletion',
        () async {
          final nonExistentPath = UspPath.parse(
            'Device.MultiInstanceObject.3.',
          );
          expect(
            () async => await repository.deleteObject(nonExistentPath),
            throwsA(
              isA<UspException>().having((e) => e.errorCode, 'errorCode', 7002),
            ),
          );
        },
      );

      test(
        'should successfully delete an existing multi-instance object',
        () async {
          final objectPathToDelete = UspPath.parse(
            'Device.MultiInstanceObject.1.',
          );
          await repository.deleteObject(objectPathToDelete);

          final remainingObject = repository
              .getDeviceTree()
              .root
              .getChild('MultiInstanceObject')!
              .getChild('1');
          expect(remainingObject, isNull);
          // Verify that the other object still exists
          final otherObject = repository
              .getDeviceTree()
              .root
              .getChild('MultiInstanceObject')!
              .getChild('2');
          expect(otherObject, isNotNull);
        },
      );
    });
    test('operate method should throw UspException for non-existing command',
        () async {
      final commandPath = UspPath.parse('Device.Command.Reboot()');
      final inputArguments = {'123': UspValue('123', UspValueType.string)};
      expect(
        () async => await repository.operate(commandPath, inputArguments),
        throwsA(
          isA<UspException>().having((e) => e.errorCode, 'errorCode', 7002),
        ),
      );
    });

    group('updateInternally', () {
      late DeviceRepositoryImpl repository;
      late DeviceTree deviceTree;
      late MockPersistenceService mockPersistenceService;

      setUp(() {
        mockPersistenceService = MockPersistenceService();
        when(() => mockPersistenceService.save(any())).thenAnswer((_) async {});

        final param1 = UspParameter<String>(
          path: UspPath.parse('Device.Test.Param1'),
          value: UspValue<String>('initial1', UspValueType.string),
          isWritable: true,
        );
        final param2 = UspParameter<int>(
          path: UspPath.parse('Device.Test.Param2'),
          value: UspValue<int>(10, UspValueType.int),
          isWritable: false,
        );
        final testObj = UspObject(
          path: UspPath.parse('Device.Test.'),
          children: {'Param1': param1, 'Param2': param2},
        );
        deviceTree = DeviceTree(
          root: UspObject(
            path: UspPath.parse('Device.'),
            children: {'Test': testObj},
          ),
        );
        repository = DeviceRepositoryImpl(deviceTree, mockPersistenceService);
      });

      test(
        'should update parameter value without saving to persistence',
        () async {
          final path = UspPath.parse('Device.Test.Param1');
          final newValue = UspValue<String>(
            'updated',
            UspValueType.string,
          ); // Explicit type arg

          await repository.updateInternally(path, newValue);

          final updatedNode = repository
              .getDeviceTree()
              .root
              .getChild('Test')!
              .getChild('Param1');
          expect(updatedNode, isA<UspParameter>()); // Check it's a UspParameter
          final updatedParam =
              updatedNode
                  as UspParameter; // Cast to UspParameter (can be dynamic)
          expect(updatedParam.value.value, 'updated');
          verifyNever(
            () => mockPersistenceService.save(any()),
          ); // Should not save
        },
      );

      test('should throw UspException if path not found', () async {
        final nonExistentPath = UspPath.parse('Device.Test.NonExistentParam');
        final newValue = UspValue('value', UspValueType.string);
        expect(
          () async =>
              await repository.updateInternally(nonExistentPath, newValue),
          throwsA(
            isA<UspException>().having((e) => e.errorCode, 'errorCode', 7002),
          ),
        );
      });

      test('should not update if node is not UspParameter', () async {
        final path = UspPath.parse('Device.Test.'); // Path to an UspObject
        final newValue = UspValue('value', UspValueType.string);

        final initialTree = repository.getDeviceTree();
        await repository.updateInternally(path, newValue);

        // Ensure tree has not changed
        expect(repository.getDeviceTree(), initialTree);
      });
    });
  });
}
