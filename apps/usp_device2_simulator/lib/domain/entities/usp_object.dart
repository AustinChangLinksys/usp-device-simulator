import 'package:usp_device2_simulator/domain/entities/usp_node.dart';
import 'package:usp_protocol_common/usp_protocol_common.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:usp_device2_simulator/domain/entities/usp_node_converter.dart';

part 'usp_object.g.dart';

@JsonSerializable(explicitToJson: true)
class UspObject extends UspNode {
  
  final Map<String, UspNode> children;

  @override
  final bool isMultiInstance;
  
  final int nextInstanceId;
  final int minEntries;

  UspObject({
    required super.path,
    super.attributes,
    this.children = const {},
    this.isMultiInstance = false,
    this.nextInstanceId = 1,
    this.minEntries = 0,
  });

  factory UspObject.fromJson(Map<String, dynamic> json) => _$UspObjectFromJson(json);
  Map<String, dynamic> toJson() => _$UspObjectToJson(this);

  // --- Interface Implementation ---

  @override
  UspNode? getChild(String name) {
    return children[name];
  }

  @override
  Iterable<UspNode> getAllChildren() {
    return children.values;
  }

  @override
  bool get isParameter => false;

  // --- CopyWith ---

  @override
  UspObject copyWith({
    UspPath? path,
    Map<String, dynamic>? attributes,
    Map<String, UspNode>? children,
    bool? isMultiInstance,
    int? nextInstanceId,
    int? minEntries,
  }) {
    return UspObject(
      path: path ?? this.path,
      attributes: attributes ?? this.attributes,
      children: children ?? this.children,
      isMultiInstance: isMultiInstance ?? this.isMultiInstance,
      nextInstanceId: nextInstanceId ?? this.nextInstanceId,
      minEntries: minEntries ?? this.minEntries,
    );
  }
}