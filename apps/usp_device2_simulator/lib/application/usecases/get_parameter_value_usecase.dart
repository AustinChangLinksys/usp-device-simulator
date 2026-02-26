import 'package:usp_device2_simulator/domain/repositories/i_device_repository.dart';
import 'package:usp_protocol_common/usp_protocol_common.dart';

class GetParameterValueUseCase {
  final IDeviceRepository _repository;

  GetParameterValueUseCase(this._repository);

  Future<Map<UspPath, UspValue>> execute(UspPath path) {
    return _repository.getParameterValue(path);
  }
}
