import 'package:usp_device2_simulator/domain/entities/device_tree.dart';

abstract class ISchemaLoader {
  Future<DeviceTree> loadSchema(String schemaContent);
}
