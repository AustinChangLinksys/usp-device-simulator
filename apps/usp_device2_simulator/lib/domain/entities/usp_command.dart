import 'package:usp_device2_simulator/domain/entities/usp_node.dart';
import 'package:usp_protocol_common/usp_protocol_common.dart';
import 'package:json_annotation/json_annotation.dart';

part 'usp_command.g.dart';

@JsonSerializable(explicitToJson: true)
class UspCommand extends UspNode {
  
  // In a real implementation, this might store definitions of Input/Output parameters (Metadata).
  // final Map<String, String> inputArgs;
  // final Map<String, String> outputArgs;

  UspCommand({
    required super.path,
    super.attributes,
  });

  // --- JSON Serialization ---
  factory UspCommand.fromJson(Map<String, dynamic> json) => _$UspCommandFromJson(json);
  Map<String, dynamic> toJson() => _$UspCommandToJson(this);

  // --- Implement children getter as required by UspNode ---
  Map<String, UspNode> get children => const {}; 

  // --- Interface Implementation (Leaf Node Behavior) ---
  @override
  UspNode? getChild(String name) => null;

  @override
  Iterable<UspNode> getAllChildren() => const Iterable.empty();

  // --- Property Identification ---
  @override
  bool get isMultiInstance => false;

  @override
  bool get isParameter => false;
  
  bool get isCommand => true; 

  // --- Add CopyWith (even if Command is typically stateless, for interface consistency) ---
  @override
  UspCommand copyWith({
    UspPath? path,
    Map<String, dynamic>? attributes,
  }) {
    return UspCommand(
      path: path ?? this.path,
      attributes: attributes ?? this.attributes,
    );
  }

  // --- Execution Logic ---
  Future<Map<String, dynamic>> execute(Map<String, dynamic> args) async {

    
    // In the future, this will connect to specific Service logic (e.g., RebootService).
    // Simulate successful return.
    return {'status': 'Success'};
  }
}