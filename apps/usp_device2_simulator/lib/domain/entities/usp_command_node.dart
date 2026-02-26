import 'package:usp_device2_simulator/domain/entities/usp_node.dart';
import 'package:usp_protocol_common/usp_protocol_common.dart';

/// Function signature for command execution logic
/// Input: parameter name -> UspValue
/// Output: parameter name -> dynamic (usually String or UspValue)
typedef CommandExecutor =
    Future<Map<String, dynamic>> Function(Map<String, UspValue> args);

class UspCommandNode extends UspNode {
  final bool isAsync;
  final Map<String, UspArgumentDefinition> inputArgs;
  final Map<String, UspArgumentDefinition> outputArgs;

  /// Stores the actual execution logic (injected by Registry)
  final CommandExecutor? _executor;

  UspCommandNode({
    required super.path,
    super.attributes,
    this.isAsync = false,
    this.inputArgs = const {},
    this.outputArgs = const {},
    CommandExecutor? executor, // Optional at construction
  }) : _executor = executor;

  // Helper to identify if it's a command
  bool get isCommand => true;

  Future<Map<String, dynamic>> execute(Map<String, UspValue> args) async {
    if (_executor == null) {
      print('❌ [Command] Implementation missing for ${path.fullPath}');

      // Throw USP exception, which will be caught by Adapter and converted to Error Response
      throw UspException(
        7000,
        'Command not implemented: ${path.fullPath}. Please check CommandRegistry.',
      );
    }

    // Call the injected function
    return await _executor(args);
  }

  // --- Interface Implementation (as is) ---
  @override
  UspNode? getChild(String name) => null;

  @override
  Iterable<UspNode> getAllChildren() => const Iterable.empty();

  @override
  bool get isMultiInstance => false;

  @override
  bool get isParameter => false;

  @override
  UspCommandNode copyWith({
    UspPath? path,
    Map<String, dynamic>? attributes,
    bool? isAsync,
    Map<String, UspArgumentDefinition>? inputArgs,
    Map<String, UspArgumentDefinition>? outputArgs,
    CommandExecutor? executor,
  }) {
    return UspCommandNode(
      path: path ?? this.path,
      attributes: attributes ?? this.attributes,
      isAsync: isAsync ?? this.isAsync,
      inputArgs: inputArgs ?? this.inputArgs,
      outputArgs: outputArgs ?? this.outputArgs,
      executor: executor ?? _executor,
    );
  }
}
