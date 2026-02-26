import 'dart:io';
import 'dart:convert';
import 'package:args/args.dart';
import 'package:grpc/grpc.dart' as grpc;
import 'package:usp_device2_simulator/application/usecases/add_object_usecase.dart';

// Domain
import 'package:usp_device2_simulator/domain/entities/device_tree.dart';
import 'package:usp_device2_simulator/infrastructure/commands/command_registry.dart';

// Infrastructure
import 'package:usp_device2_simulator/infrastructure/repositories/device_repository_impl.dart';
import 'package:usp_device2_simulator/infrastructure/schema/xml_schema_loader.dart';
import 'package:usp_device2_simulator/infrastructure/config/json_config_loader.dart';
import 'package:usp_device2_simulator/infrastructure/transport/grpc_proxy_service.dart';
import 'package:usp_device2_simulator/infrastructure/transport/websocket_mtp_service.dart';
import 'package:usp_device2_simulator/infrastructure/transport/mqtt_mtp_service.dart';
import 'package:usp_device2_simulator/infrastructure/transport/http_mtp_service.dart';
import 'package:usp_device2_simulator/infrastructure/adapter/usp_message_adapter.dart';
import 'package:usp_device2_simulator/infrastructure/provisioning/smart_provisioner.dart';
import 'package:usp_device2_simulator/infrastructure/persistence/i_persistence_service.dart';
import 'package:usp_protocol_common/usp_protocol_common.dart';

/// In-Memory Persistence Implementation
class InMemoryPersistence implements IPersistenceService {
  @override
  Future<DeviceTree?> load() async => null;
  @override
  Future<void> save(DeviceTree t) async {}
}

void main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption('schema', defaultsTo: 'test/data/tr-181-2-20-0-usp-full.xml')
    ..addOption('config', defaultsTo: 'test/data/router_data_full.json')
    ..addOption('port', defaultsTo: '8080', help: 'WebSocket Port')
    ..addOption('http-port', defaultsTo: '8081', help: 'HTTP API Port')
    ..addOption('grpc-port', defaultsTo: '50051', help: 'gRPC Port')
    ..addOption(
      'mtp',
      defaultsTo: 'websocket',
      allowed: ['websocket', 'mqtt', 'grpc', 'http', 'all'],
      help: 'The MTP service to use.',
    )
    ..addOption('agent-id', defaultsTo: 'proto::agent', help: 'USP Endpoint ID')
    ..addOption('broker', defaultsTo: 'localhost', help: 'MQTT Broker Host')
    ..addOption('broker-port', defaultsTo: '1883', help: 'MQTT Broker Port');

  final argResults = parser.parse(arguments);

  final schemaPath = argResults['schema'];
  final configPath = argResults['config'];
  final wsPort = int.tryParse(argResults['port']) ?? 8080;
  final httpPort = int.tryParse(argResults['http-port']) ?? 8081;
  final grpcPort = int.tryParse(argResults['grpc-port']) ?? 50051;
  final mtpMode = argResults['mtp'];
  final agentId = argResults['agent-id'];
  final brokerHost = argResults['broker'] ?? 'localhost';
  final brokerPort = int.tryParse(argResults['broker-port']) ?? 1883;

  print('===============================================================');
  print('🚀 USP Device:2 Simulator Server (Agent ID: $agentId)');
  print('===============================================================\n');

  try {
    // 1. Load Schema
    final xmlFile = File(schemaPath);
    if (!await xmlFile.exists()) {
      print('❌ Error: Schema file not found: $schemaPath');
      exit(1);
    }
    final xmlContent = await xmlFile.readAsString();
    final schemaLoader = XmlSchemaLoader();
    final schemaTree = await schemaLoader.loadSchema(xmlContent);
    print('✅ Schema Loaded. Root: ${schemaTree.root.name}\n');

    // 2. Initialize Repository
    final repo = DeviceRepositoryImpl(schemaTree, InMemoryPersistence());
    final addObjectUseCase = AddObjectUseCase(repo);

    // Inject command implementations
    final commandRegistry = CommandRegistry();
    commandRegistry.registerDefaults();
    await repo.injectCommandImplementations(commandRegistry);

    // 3. Provisioning
    final configFile = File(configPath);
    if (await configFile.exists()) {
      print('🌱 Provisioning from: $configPath');
      final jsonContent = await configFile.readAsString();
      final Map<String, dynamic> configMap = jsonDecode(jsonContent);
      await SmartProvisioner(addObjectUseCase).provision(configMap);

      // 4. Load Values
      print('🎨 Applying Config Values...');
      final configLoader = JsonConfigLoader();
      final finalTree = await configLoader.loadConfig(
        repo.getDeviceTree(),
        configPath,
      );
      await repo.updateTree(finalTree);
      print('✅ Configuration Applied.\n');
    }

    // ---------------------------------------------------------
    // 5. Start Services
    // ---------------------------------------------------------
    final adapter = UspMessageAdapter(repo);
    final uspRecordHelper = UspRecordHelper();

    WebSocketMtpService? wsService;
    MqttMtpService? mqttService;
    HttpMtpService? httpService;
    grpc.Server? grpcServer;

    // A. Start gRPC Server (Gateway Proxy)
    print('🚀 Starting gRPC Gateway on port $grpcPort...');
    final grpcServiceDef = GrpcProxyService(
      adapter,
      agentId,
      recordHelper: uspRecordHelper,
    );
    grpcServer = grpc.Server.create(services: [grpcServiceDef]);
    await grpcServer.serve(address: InternetAddress.anyIPv4, port: grpcPort);
    print('✅ gRPC Gateway listening on port $grpcPort');

    // B. Start MTP (Agent Transport)
    if (mtpMode == 'websocket' || mtpMode == 'all') {
      print('🔌 Starting WebSocket MTP...');
      wsService = WebSocketMtpService(adapter);
      await wsService.start(port: wsPort);
      print('✅ WebSocket listening on ws://0.0.0.0:$wsPort');
    }

    // C. Start HTTP API MTP
    if (mtpMode == 'http' || mtpMode == 'all') {
      print('🔌 Starting HTTP API MTP...');
      httpService = HttpMtpService(adapter: adapter);
      await httpService.start(port: httpPort);
    }

    if (mtpMode == 'mqtt' || mtpMode == 'all') {
      print('🔌 Starting MQTT MTP...');
      mqttService = MqttMtpService(
        adapter: adapter,
        agentId: agentId,
        brokerHost: brokerHost,
        brokerPort: brokerPort,
      );
      try {
        await mqttService.start();
        print('✅ MQTT Connected');
      } catch (e) {
        print('⚠️ MQTT Failed: $e');
      }
    }

    print('\n✨ Simulator is running. Press Ctrl+C to stop.');

    // 6. Graceful Shutdown
    await ProcessSignal.sigint.watch().first;
    print('\n🛑 Stopping Services...');

    await grpcServer.shutdown();
    await wsService?.stop();
    await mqttService?.stop();
    await httpService?.stop();

    print('👋 Bye!');
    exit(0);
  } catch (e, stack) {
    print('❌ Critical Error: $e');
    print(stack);
    exit(1);
  }
}
