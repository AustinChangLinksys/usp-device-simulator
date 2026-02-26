import 'package:usp_device2_simulator/domain/repositories/i_device_repository.dart';
import 'package:usp_protocol_common/usp_protocol_common.dart';

class SetParameterValueUseCase {
  final IDeviceRepository _repository;

  SetParameterValueUseCase(this._repository);

  Future<void> execute(UspPath path, UspValue value) {
    return _repository.setParameterValue(path, value);
  }
}
