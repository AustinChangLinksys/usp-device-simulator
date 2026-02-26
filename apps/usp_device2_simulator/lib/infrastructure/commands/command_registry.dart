import 'dart:async';
import 'package:usp_protocol_common/usp_protocol_common.dart';
import '../../domain/entities/usp_command_node.dart';

class CommandRegistry {
  /// Stores the mapping of path -> execution function
  final Map<String, CommandExecutor> _implementations = {};

  /// Registers default commands
  void registerDefaults() {
    register('Device.Reboot()', _reboot);
    register('Device.FactoryReset()', _factoryReset);
    // ... more commands
  }

  /// Registers a single command
  void register(String path, CommandExecutor executor) {
    _implementations[path] = executor;
  }

  /// Get all registered items
  Map<String, CommandExecutor> get all => _implementations;

  // --- Concrete Implementation Logic ---

  Future<Map<String, dynamic>> _reboot(Map<String, UspValue> args) async {
    print('💥 [Command] System is Rebooting...');
    // Simulate time-consuming operation
    await Future.delayed(const Duration(seconds: 2));
    
    // TODO: Can call MqttService.disconnect() here to simulate disconnection
    
    print('🚀 [Command] Reboot sequence initiated.');
    return {}; // Reboot usually has no output parameters
  }

  Future<Map<String, dynamic>> _factoryReset(Map<String, UspValue> args) async {
    print('⚠️ [Command] Factory Resetting...');
    return {'Status': 'Resetting'};
  }
}