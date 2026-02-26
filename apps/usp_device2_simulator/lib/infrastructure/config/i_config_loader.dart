import 'package:usp_device2_simulator/domain/entities/device_tree.dart';

abstract class IConfigLoader {
  /// Loads configuration from a given source and applies it to the DeviceTree.
  Future<DeviceTree> loadConfig(DeviceTree initialTree, String configPath);
}
