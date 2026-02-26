import 'package:usp_protocol_common/usp_protocol_common.dart';

abstract class UspNode implements ITraversableNode<UspNode> {
  final UspPath path;
  final Map<String, dynamic> attributes;

  /// Use const constructor for performance optimization
  const UspNode({
    required this.path,
    this.attributes = const {},
  });

  // --- Interface implementation requirements (mandatory) ---
  
  @override
  String get name => path.name; // Derived directly from path

  // --- Interface methods (keep abstract, implemented by subclasses) ---
  
  @override
  UspNode? getChild(String name);

  @override
  Iterable<UspNode> getAllChildren();

  // --- Domain Specific Properties ---
  // These are not part of the interface, no @override needed

  /// Get parent path (Nullable)
  UspPath? get parentPath => path.parent;

  /// Determine if it is a multi-instance object (default false)
  bool get isMultiInstance => false;

  /// Determine if it is a parameter (default false)
  bool get isParameter => false;
  
  /// Abstract method for Copy-on-Write (used by Riverpod for state updates)
  UspNode copyWith({
    UspPath? path,
    Map<String, dynamic>? attributes,
  });
}