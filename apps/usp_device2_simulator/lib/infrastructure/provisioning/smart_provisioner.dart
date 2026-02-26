import 'package:usp_device2_simulator/application/usecases/add_object_usecase.dart';
import 'package:usp_protocol_common/usp_protocol_common.dart';

class SmartProvisioner {
  final AddObjectUseCase _addObjectUseCase;

  SmartProvisioner(this._addObjectUseCase);

  /// Automatically creates missing instances based on the Config Map.
  ///
  /// This analyzes the JSON configuration keys (e.g., "Device.WiFi.Radio.1.Channel")
  /// and proactively calls [AddObjectUseCase] to create intermediate instances (e.g., "Device.WiFi.Radio.1")
  /// before values are applied.
  Future<void> provision(Map<String, dynamic> configMap) async {
    final createdInstances = <String>{};
    final instancesToCreate = <String>{};

    // 1. Scan all paths to identify segments containing numbers (Identifying Instances)
    for (final key in configMap.keys) {
      final pathSegments = key.split('.');
      for (int i = 0; i < pathSegments.length; i++) {
        // If a path segment is a number, capture the path up to this point
        // e.g., Device.IP.Interface.1
        if (int.tryParse(pathSegments[i]) != null) {
          instancesToCreate.add(pathSegments.sublist(0, i + 1).join('.'));
        }
      }
    }

    // 2. Sort: Shortest to longest (Ensure Parent Instance is created first)
    // e.g., Device.IP.Interface.1 must be created before Device.IP.Interface.1.IPv4Address.1
    final sortedInstances = instancesToCreate.toList()
      ..sort((a, b) => a.split('.').length.compareTo(b.split('.').length));

    // 3. Execute AddObject
    int successCount = 0;
    for (final fullInstancePath in sortedInstances) {
      if (createdInstances.contains(fullInstancePath)) continue;

      final pathObj = UspPath.parse(fullInstancePath);
      
      // Target is the Parent (Table Object), e.g., Device.IP.Interface
      // fullInstancePath: ...Interface.1
      // parentPath: ...Interface
      final parentPath = pathObj.parent!; 
      final instanceId = int.parse(pathObj.segments.last);

      try {
        await _addObjectUseCase.execute(
          parentPath, 
          "Ignored", // Template name is usually automatically handled internally as {i}
          instanceId: instanceId
        );
        createdInstances.add(fullInstancePath);
        successCount++;

      } catch (e) {
        // Ignore errors: Instance might already exist, or Schema doesn't support Add.
        // This is expected behavior as we are just attempting to "fill in" the structure.

      }
    }
    
    if (successCount > 0) {
      print("   [Provisioner] Auto-provisioned $successCount instances.");
    }
  }
}