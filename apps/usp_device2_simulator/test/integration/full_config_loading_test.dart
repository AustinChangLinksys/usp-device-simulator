import 'dart:io';
import 'dart:convert';
import 'package:test/test.dart';
import 'package:usp_device2_simulator/domain/entities/device_tree.dart';
import 'package:usp_device2_simulator/domain/entities/usp_node.dart';
import 'package:usp_device2_simulator/domain/entities/usp_parameter.dart';
import 'package:usp_protocol_common/usp_protocol_common.dart';
import 'package:usp_device2_simulator/infrastructure/schema/xml_schema_loader.dart';
import 'package:usp_device2_simulator/infrastructure/config/json_config_loader.dart';
import 'package:usp_device2_simulator/infrastructure/repositories/device_repository_impl.dart';
import 'package:usp_device2_simulator/infrastructure/persistence/i_persistence_service.dart';
import 'package:usp_device2_simulator/application/usecases/add_object_usecase.dart';
import 'package:usp_device2_simulator/infrastructure/provisioning/smart_provisioner.dart';

// Mock Persistence
class MockPersistenceService implements IPersistenceService {
  @override
  Future<DeviceTree> load() async {
    throw UnimplementedError();
  }

  @override
  Future<void> save(DeviceTree deviceTree) async {}
}

void main() {
  group('Real-World Full Router Scenario', () {
    test(
      'should initialize a High-End Router from Full Schema and Config',
      () async {
        // ==================================================================
        // Step 1: Load the HUGE Official Schema
        // ==================================================================
        print("1. Loading Official Schema...");
        final xmlSchemaContent = await File(
          'test/data/tr-181-2-20-0-usp-full.xml',
        ).readAsString();
        final schemaLoader = XmlSchemaLoader();

        final stopwatch = Stopwatch()..start();
        final deviceTree = await schemaLoader.loadSchema(xmlSchemaContent);
        stopwatch.stop();
        print(
          "   -> Schema Loaded in ${stopwatch.elapsedMilliseconds} ms. Root: ${deviceTree.root.name}",
        );

        // ==================================================================
        // Step 2: Prepare System
        // ==================================================================
        final mockPersistenceService = MockPersistenceService();
        final deviceRepository = DeviceRepositoryImpl(
          deviceTree,
          mockPersistenceService,
        );
        final addObjectUseCase = AddObjectUseCase(deviceRepository);

        // ==================================================================
        // Step 3: Smart Provisioning (Create Instances from JSON structure)
        // ==================================================================
        print("2. Provisioning Instances from Full Config...");
        final jsonFile = File('test/data/router_data_full.json');
        final jsonContent = await jsonFile.readAsString();
        final Map<String, dynamic> configMap = jsonDecode(jsonContent);

        // [Refactor] Use the actual SmartProvisioner class
        final provisioner = SmartProvisioner(addObjectUseCase);
        await provisioner.provision(configMap);

        // Get the tree with newly created instances (but default values)
        final treeWithInstances = deviceRepository.getDeviceTree();
        print("   -> Provisioning done.");

        // ==================================================================
        // Step 4: Apply Values (Fill Data)
        // ==================================================================
        print("3. Applying Value Configuration...");
        final configLoader = JsonConfigLoader();
        final finalTree = await configLoader.loadConfig(
          treeWithInstances,
          jsonFile.path,
        );
        await deviceRepository.updateTree(finalTree);
        print("   -> Configuration applied.");

        // ==================================================================
        // Step 5: Comprehensive Verification (Assertions)
        // ==================================================================
        print("4. Verifying Data Integrity...");
        final pathResolver = PathResolver();

        // Helper to retrieve parameter values
        dynamic getValue(String path) {
          // [Check] Explicitly specify generic type <UspNode>
          final nodes = pathResolver.resolve<UspNode>(
            finalTree.root,
            UspPath.parse(path),
          );
          expect(nodes, isNotEmpty, reason: 'Path not found: $path');
          return (nodes.first as UspParameter).value.value;
        }

        // 5.1 Device Info
        expect(getValue('Device.DeviceInfo.ModelName'), 'DartSim-Ultra-2.20');
        expect(getValue('Device.DeviceInfo.UpTime'), 86400);

        // 5.2 Ethernet (Layer 1/2)
        expect(getValue('Device.Ethernet.Interface.1.Name'), 'eth_wan');
        expect(
          getValue('Device.Ethernet.Interface.2.MACAddress'),
          'AC:DE:48:00:00:02',
        );

        // 5.3 IP Layer (Layer 3) - WAN Static IP
        expect(getValue('Device.IP.Interface.1.Name'), 'WAN_Connection');
        expect(
          getValue('Device.IP.Interface.1.IPv4Address.1.IPAddress'),
          '203.0.113.15',
        );
        expect(
          getValue('Device.IP.Interface.1.LowerLayers'),
          'Device.Ethernet.Interface.1',
        );

        // 5.4 IPv6
        expect(
          getValue('Device.IP.Interface.1.IPv6Address.1.IPAddress'),
          '2001:db8::1',
        );

        // 5.5 DHCP Server
        expect(getValue('Device.DHCPv4.Server.Enable'), true);
        expect(
          getValue('Device.DHCPv4.Server.Pool.1.MinAddress'),
          '192.168.1.100',
        );

        // 5.6 DNS Client
        expect(getValue('Device.DNS.Client.Server.1.DNSServer'), '8.8.8.8');

        // 5.7 WiFi 6E (Tri-Band)
        // Radio 3 (6GHz)
        expect(getValue('Device.WiFi.Radio.3.OperatingFrequencyBand'), '6GHz');
        expect(getValue('Device.WiFi.Radio.3.Channel'), 37);
        expect(getValue('Device.WiFi.Radio.3.OperatingStandards'), 'be');

        // SSID & Security
        expect(getValue('Device.WiFi.SSID.3.SSID'), 'DartSim_Pro_6G');
        expect(
          getValue('Device.WiFi.AccessPoint.3.Security.ModeEnabled'),
          'WPA3-Personal',
        );
        expect(
          getValue('Device.WiFi.AccessPoint.3.Security.KeyPassphrase'),
          'future_proof',
        );

        print("✅ All assertions passed!");
      },
      timeout: Timeout(Duration(seconds: 30)),
    );
  });
}
