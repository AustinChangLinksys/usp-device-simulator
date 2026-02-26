import 'dart:convert';
import 'dart:io';

import 'package:usp_device2_simulator/domain/entities/device_tree.dart';
import 'package:usp_device2_simulator/infrastructure/persistence/i_persistence_service.dart';

class JsonPersistenceService implements IPersistenceService {
  JsonPersistenceService({required this.filePath});

  final String filePath;

  @override
  Future<DeviceTree?> load() async {
    final file = File(filePath);
    if (!await file.exists()) {
      return null;
    }

    final content = await file.readAsString();
    if (content.isEmpty) {
      return null;
    }

    final json = jsonDecode(content) as Map<String, dynamic>;
    return DeviceTree.fromJson(json);
  }

  @override
  Future<void> save(DeviceTree deviceTree) async {
    final file = File(filePath);
    final json = deviceTree.toJson();
    final content = jsonEncode(json);
    await file.writeAsString(content);
  }
}