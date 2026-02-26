import 'package:usp_device2_simulator/domain/repositories/i_device_repository.dart';
import 'package:usp_protocol_common/usp_protocol_common.dart';

class DeleteObjectUseCase {
  final IDeviceRepository _repository;

  DeleteObjectUseCase(this._repository);

  Future<void> execute(UspPath objectPath) {
    return _repository.deleteObject(objectPath);
  }
}
