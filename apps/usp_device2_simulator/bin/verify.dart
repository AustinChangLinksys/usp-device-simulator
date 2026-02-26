// ignore_for_file: avoid_print

import 'dart:io';
import 'dart:convert';

// Domain
import 'package:usp_device2_simulator/domain/entities/device_tree.dart';
import 'package:usp_device2_simulator/domain/entities/usp_node.dart';
import 'package:usp_device2_simulator/domain/entities/usp_object.dart';
import 'package:usp_device2_simulator/domain/entities/usp_parameter.dart';

// Infrastructure
import 'package:usp_device2_simulator/infrastructure/schema/xml_schema_loader.dart';
import 'package:usp_device2_simulator/infrastructure/config/json_config_loader.dart';
import 'package:usp_device2_simulator/infrastructure/repositories/device_repository_impl.dart';
import 'package:usp_device2_simulator/infrastructure/persistence/i_persistence_service.dart';
import 'package:usp_device2_simulator/infrastructure/provisioning/smart_provisioner.dart'; 

// Application
import 'package:usp_device2_simulator/application/usecases/add_object_usecase.dart';

/// Mock Persistence
class MockPersistenceService implements IPersistenceService {
  @override
  Future<DeviceTree> load() async { throw UnimplementedError(); }
  @override
  Future<void> save(DeviceTree deviceTree) async {}
}

void main(List<String> arguments) async {
  // Default paths
  String xmlPath = 'test/data/router_scheme.xml';
  String jsonPath = 'test/data/router_data.json';

  // Handle argument input
  if (arguments.isNotEmpty) {
    if (arguments.contains('-h') || arguments.contains('--help')) {
      print('Usage: dart bin/verify_device.dart [xml_schema_path] [json_config_path]');
      return;
    }

    // Override paths if provided
    if (arguments.isNotEmpty) xmlPath = arguments[0];
    if (arguments.length > 1) jsonPath = arguments[1];
  }

  print('===============================================================');
  print('🚀 USP Device:2 Simulator - Self Verification Tool');
  print('===============================================================\n');

  try {
    // ---------------------------------------------------------
    // 1. Load Schema (Build Skeleton)
    // ---------------------------------------------------------
    print('📦 Loading XML Schema from: $xmlPath');
    final xmlFile = File(xmlPath);
    if (!xmlFile.existsSync()) {
      print('❌ Error: XML file not found at $xmlPath');
      print('   Tip: Check the path or run without arguments to use defaults.');
      return;
    }
    final xmlContent = await xmlFile.readAsString();
    final schemaLoader = XmlSchemaLoader();
    final deviceTree = await schemaLoader.loadSchema(xmlContent);
    print('✅ Schema Loaded. Root: ${deviceTree.root.name}\n');

    // ---------------------------------------------------------
    // 2. Initialize System
    // ---------------------------------------------------------
    final repo = DeviceRepositoryImpl(deviceTree, MockPersistenceService());
    final addUseCase = AddObjectUseCase(repo);

    // ---------------------------------------------------------
    // 3. Smart Provisioning (Create Instances)
    // ---------------------------------------------------------
    print('🌱 Provisioning Instances from JSON: $jsonPath');
    final jsonFile = File(jsonPath);
    if (!jsonFile.existsSync()) {
      print('❌ Error: JSON file not found at $jsonPath');
      return;
    }
    final jsonContent = await jsonFile.readAsString();
    final Map<String, dynamic> configMap = jsonDecode(jsonContent);

    // Use SmartProvisioner instead of local function
    final provisioner = SmartProvisioner(addUseCase);
    await provisioner.provision(configMap);
    
    print('✅ Provisioning Complete.\n');

    // ---------------------------------------------------------
    // 4. Apply Config Values (Fill Data)
    // ---------------------------------------------------------
    print('🎨 Applying Configuration Values...');
    final configLoader = JsonConfigLoader();
    final treeWithInstances = repo.getDeviceTree(); 
    final finalTree = await configLoader.loadConfig(treeWithInstances, jsonPath);
    
    await repo.updateTree(finalTree);
    print('✅ Configuration Applied.\n');

    // ---------------------------------------------------------
    // 5. Dump Tree (Print Result)
    // ---------------------------------------------------------
    print('===============================================================');
    print('🌳 Device Data Model Dump');
    print('===============================================================');
    
    _printNode(finalTree.root, "");

    print('\n✨ Verification Finished Successfully!');

  } catch (e, stack) {
    print('❌ Critical Error: $e');
    print(stack);
  }
}

/// Helper function to recursively print nodes
void _printNode(UspNode node, String indent) {
  if (node is UspObject) {
    final marker = node.isMultiInstance ? '[Instance/Template]' : '[Obj]';
    print('$indent$marker ${node.name} (${node.path.fullPath})');

    final children = node.children.values.toList();
    // Sort children: Parameters first, then Objects
    children.sort((a, b) {
      if (a.runtimeType == b.runtimeType) return a.name.compareTo(b.name);
      return a is UspParameter ? -1 : 1; 
    });

    for (final child in children) {
      _printNode(child, '$indent  ');
    }
  } else if (node is UspParameter) {
    final access = node.isWritable ? 'RW' : 'RO';
    print('$indent- ${node.name}: ${node.value.value}  <$access, ${node.value.type.name}>');
  }
}