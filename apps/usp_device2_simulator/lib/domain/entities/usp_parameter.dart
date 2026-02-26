import 'package:usp_device2_simulator/domain/entities/usp_node.dart';
import 'package:usp_protocol_common/usp_protocol_common.dart';
import 'package:json_annotation/json_annotation.dart';

part 'usp_parameter.g.dart';

@JsonSerializable(explicitToJson: true, genericArgumentFactories: true)
class UspParameter<T> extends UspNode {
  final UspValue<T> value;
  final bool isWritable;
  final UspParamConstraints constraints;

  UspParameter({
    required super.path,
    super.attributes,
    required this.value,
    this.isWritable = false,
    this.constraints = const UspParamConstraints(),
  });

  factory UspParameter.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) => _$UspParameterFromJson(json, fromJsonT);
  Map<String, dynamic> toJson(Object? Function(T value) toJsonT) =>
      _$UspParameterToJson(this, toJsonT);

  @override
  UspNode? getChild(String name) => null;

  @override
  Iterable<UspNode> getAllChildren() => const Iterable.empty();

  @override
  bool get isMultiInstance => false;

  @override
  bool get isParameter => true;

  void validate(UspValue<T> newValue) {
    if (!isWritable) {
      throw UspException(7003, 'Parameter ${path.fullPath} is Read-Only.');
    }

    if (newValue.type != value.type) {
      throw UspException(
        7003,
        'Invalid Type: Expected ${value.type}, got ${newValue.type}',
      );
    }

    final val = newValue.value;

    if (constraints.enumeration.isNotEmpty) {
      if (!constraints.enumeration.contains(val.toString())) {
        throw UspException(
          7003,
          'Invalid Value: "$val" is not in allowed list ${constraints.enumeration}',
        );
      }
    }

    if (val is num) {
      // int or double
      if (constraints.min != null && val < constraints.min!) {
        throw UspException(7003, 'Value too small: $val < ${constraints.min}');
      }
      if (constraints.max != null && val > constraints.max!) {
        throw UspException(7003, 'Value too large: $val > ${constraints.max}');
      }
    }

    if (val is String) {
      if (constraints.maxLength != null &&
          val.length > constraints.maxLength!) {
        throw UspException(
          7003,
          'String too long: ${val.length} > ${constraints.maxLength}',
        );
      }
    }
  }

  @override
  UspParameter<T> copyWith({
    UspPath? path,
    UspValue<T>? value,
    bool? isWritable,
    UspParamConstraints? constraints,
    Map<String, dynamic>? attributes,
  }) {
    return UspParameter<T>(
      path: path ?? this.path,
      value: value ?? this.value,
      isWritable: isWritable ?? this.isWritable,
      constraints: constraints ?? this.constraints,
      attributes: attributes ?? this.attributes,
    );
  }
}
