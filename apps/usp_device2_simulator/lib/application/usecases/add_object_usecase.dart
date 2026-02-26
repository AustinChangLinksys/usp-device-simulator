import 'package:usp_device2_simulator/domain/repositories/i_device_repository.dart';
import 'package:usp_protocol_common/usp_protocol_common.dart';

class AddObjectUseCase {
  final IDeviceRepository _repository;

  AddObjectUseCase(this._repository);

  Future<UspPath> execute(UspPath parentPath, String objectTemplateName, {int? instanceId}) {
    return _repository.addObject(parentPath, objectTemplateName, instanceId: instanceId);
  }
}
