import 'package:usp_device2_simulator/domain/entities/device_tree.dart';

abstract class IPersistenceService {
  Future<void> save(DeviceTree deviceTree);
  Future<DeviceTree?> load();
}
