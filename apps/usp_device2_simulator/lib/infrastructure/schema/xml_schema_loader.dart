import 'package:usp_device2_simulator/domain/entities/device_tree.dart';
import 'package:usp_device2_simulator/domain/entities/usp_node.dart';
import 'package:usp_device2_simulator/domain/entities/usp_object.dart';
import 'package:usp_device2_simulator/domain/entities/usp_parameter.dart';
import 'package:usp_protocol_common/usp_protocol_common.dart';
import 'package:usp_device2_simulator/infrastructure/schema/i_schema_loader.dart';
import 'package:xml/xml.dart';
import 'package:collection/collection.dart'; // Required for firstWhereOrNull

import 'package:usp_device2_simulator/domain/entities/usp_command_node.dart';

class XmlSchemaLoader implements ISchemaLoader {
  /// Standardize removal of trailing dots to ensure all Map Keys are consistent
  String _normalizeKey(String path) {
    return path.endsWith('.') ? path.substring(0, path.length - 1) : path;
  }

  @override
  Future<DeviceTree> loadSchema(String schemaContent) async {
    final document = XmlDocument.parse(schemaContent);

    // Locate root elements
    final dmDocument = document.descendants.whereType<XmlElement>().firstWhere(
      (element) => element.name.local == 'document',
      orElse: () =>
          throw UspException(7001, 'Root <document> element not found.'),
    );
    final modelElement = dmDocument.descendants
        .whereType<XmlElement>()
        .firstWhere(
          (element) => element.name.local == 'model',
          orElse: () => throw UspException(
            7001,
            '<model> element not found within <document>.',
          ),
        );

    final flatNodes = <String, UspNode>{};

    // ----------------------------------------------------------------------
    // Pass 1: Parse Objects & Create Implied Parents
    // ----------------------------------------------------------------------
    for (final element
        in modelElement.descendants.whereType<XmlElement>().where(
          (e) => e.name.local == 'object',
        )) {
      // Ignore objects without a name (e.g., profile references)
      final nameAttr = element.getAttribute('name');
      if (nameAttr == null || nameAttr.isEmpty) continue;

      final newObject = _parseObjectElement(element);
      final key = _normalizeKey(newObject.path.fullPath);
      flatNodes[key] = newObject;

      // Handle Implied Parent for {i} (Multi-instance template)
      if (newObject.path.segments.last.contains('{i}')) {
        final impliedParentPathSegments = List<String>.from(
          newObject.path.segments,
        );
        impliedParentPathSegments.removeLast(); // Remove '{i}'

        if (impliedParentPathSegments.isNotEmpty) {
          final impliedParentPath = UspPath(impliedParentPathSegments);
          final impliedKey = _normalizeKey(impliedParentPath.fullPath);

          if (!flatNodes.containsKey(impliedKey)) {
            final impliedParent = UspObject(
              path: impliedParentPath,
              isMultiInstance: false, // The Table object itself is a singleton
              children: const {},
            );
            flatNodes[impliedKey] = impliedParent;
          }
        }
      }
    }

    // ----------------------------------------------------------------------
    // Pass 2: Parse Parameters & Attach to Objects
    // ----------------------------------------------------------------------
    for (final element
        in modelElement.descendants.whereType<XmlElement>().where(
          (e) => e.name.local == 'parameter',
        )) {
      final parentElement = element.parentElement;
      if (parentElement != null && parentElement.name.local == 'object') {
        final parentRawName = parentElement.getAttribute('name');
        if (parentRawName == null || parentRawName.isEmpty) continue;

        final parentKey = _normalizeKey(parentRawName);

        // Check strict existence of parent object
        if (!flatNodes.containsKey(parentKey)) {
          // Retry with explicit UspPath parsing just in case XML format is irregular
          final fallbackPath = UspPath.parse(parentRawName);
          final fallbackKey = _normalizeKey(fallbackPath.fullPath);
          if (!flatNodes.containsKey(fallbackKey)) {
            // Skip if parent is not found (likely a parameter inside a command or profile)
            continue;
          }
        }

        // Double check parent is an Object (not a Command or other node)
        if (flatNodes[parentKey] is! UspObject) continue;

        UspObject parentObject = flatNodes[parentKey]! as UspObject;
        final newParam = _parseParameterElement(element, parentObject);

        // Copy-on-Write update
        final newChildren = Map<String, UspNode>.from(parentObject.children);
        newChildren[newParam.name] = newParam;
        flatNodes[parentKey] = parentObject.copyWith(children: newChildren);
      }
    }

    // ----------------------------------------------------------------------
    // Pass 2.5: Parse Commands & Attach to Objects
    // ----------------------------------------------------------------------
    for (final element
        in modelElement.descendants.whereType<XmlElement>().where(
          (e) => e.name.local == 'command',
        )) {
      final parentElement = element.parentElement;
      if (parentElement != null && parentElement.name.local == 'object') {
        final parentRawName = parentElement.getAttribute('name');
        if (parentRawName == null || parentRawName.isEmpty) continue;

        final parentKey = _normalizeKey(parentRawName);

        if (!flatNodes.containsKey(parentKey)) {
          // Command must belong to an Object
          continue;
        }

        UspObject parentObject = flatNodes[parentKey]! as UspObject;
        final newCommand = _parseCommandElement(element, parentObject);

        // Copy-on-Write update
        final newChildren = Map<String, UspNode>.from(parentObject.children);
        newChildren[newCommand.name] = newCommand;
        flatNodes[parentKey] = parentObject.copyWith(children: newChildren);
      }
    }

    // ----------------------------------------------------------------------
    // Pass 3: Build Hierarchy (Bottom-Up Approach)
    // ----------------------------------------------------------------------
    final rootKey = 'Device';
    if (!flatNodes.containsKey(rootKey)) {
      flatNodes[rootKey] = UspObject(
        path: UspPath.parse(rootKey),
        children: const {},
      );
    }

    // Sort by path length DESCENDING (process deepest nodes first)
    final sortedKeys = flatNodes.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));

    for (final childKey in sortedKeys) {
      if (childKey == rootKey) continue;

      final node = flatNodes[childKey]!;
      final parentPath = node.path.parent;

      if (parentPath == null) continue;

      final parentKey = _normalizeKey(parentPath.fullPath);

      if (flatNodes.containsKey(parentKey)) {
        final parent = flatNodes[parentKey]! as UspObject;

        // Attach child to parent
        final newChildren = Map<String, UspNode>.from(parent.children);
        newChildren[node.name] = node;

        // Update parent in the flat map
        flatNodes[parentKey] = parent.copyWith(children: newChildren);
      }
    }

    final finalRoot = flatNodes[rootKey] as UspObject?;
    if (finalRoot == null) throw UspException(7001, 'Root not found');

    return DeviceTree(root: finalRoot);
  }

  // --- Helper Methods ---

  UspObject _parseObjectElement(XmlElement element) {
    final rawName = element.getAttribute('name') ?? element.name.local;
    final path = UspPath.parse(rawName);
    final isMultiInstance =
        element.getAttribute('maxEntries') != null &&
        element.getAttribute('maxEntries') != '1';

    return UspObject(
      path: path,
      children: const {},
      attributes: {},
      isMultiInstance: isMultiInstance,
    );
  }

  UspParameter _parseParameterElement(XmlElement element, UspObject parent) {
    final rawName = element.getAttribute('name')!;
    final path = UspPath.parse('${parent.path.fullPath}.$rawName');
    final access = element.getAttribute('access');
    final isWritable = access != 'readOnly';

    final syntaxElement = element.children.whereType<XmlElement>().firstWhere(
      (e) => e.name.local == 'syntax',
    );
    final valueType = _determineUspValueType(syntaxElement);

    return UspParameter(
      path: path,
      value: UspValue(_getDefaultValue(valueType), valueType),
      isWritable: isWritable,
    );
  }

  /// Parses a <command> element, extracting input and output argument metadata.
  UspCommandNode _parseCommandElement(XmlElement element, UspObject parent) {
    final rawName = element.getAttribute('name')!;
    final path = UspPath.parse('${parent.path.fullPath}.$rawName');
    final commandType = element.getAttribute('commandType');
    final isAsync = commandType == 'asynchronous';

    // Use firstWhereOrNull for safety (inputs/outputs are optional)
    final inputElement = element.children
        .whereType<XmlElement>()
        .firstWhereOrNull((e) => e.name.local == 'input');

    final outputElement = element.children
        .whereType<XmlElement>()
        .firstWhereOrNull((e) => e.name.local == 'output');

    // Parse arguments (handles null inputElement gracefully)
    final inputArgs = _parseArguments(inputElement);
    final outputArgs = _parseArguments(outputElement);

    return UspCommandNode(
      path: path,
      isAsync: isAsync,
      inputArgs: inputArgs,
      outputArgs: outputArgs,
    );
  }

  /// Helper to parse <argument> or <parameter> tags inside command I/O blocks.
  Map<String, UspArgumentDefinition> _parseArguments(XmlElement? element) {
    // Return empty map if no input/output block exists
    if (element == null) return const {};

    final args = <String, UspArgumentDefinition>{};

    // Arguments in USP XML can be tagged as <parameter> or <argument>
    for (final paramElement in element.children.whereType<XmlElement>().where(
      (e) => e.name.local == 'parameter' || e.name.local == 'argument',
    )) {
      final name = paramElement.getAttribute('name');
      if (name == null) continue;

      final syntaxElement = paramElement.children
          .whereType<XmlElement>()
          .firstWhereOrNull((e) => e.name.local == 'syntax');

      // Default to string if syntax is missing
      final valueType = syntaxElement != null
          ? _determineUspValueType(syntaxElement)
          : UspValueType.string;

      args[name] = UspArgumentDefinition(name: name, type: valueType);
    }
    return args;
  }

  UspValueType _determineUspValueType(XmlElement syntaxElement) {
    if (syntaxElement.children.isEmpty) return UspValueType.string;
    final actualTypeElement = syntaxElement.children
        .whereType<XmlElement>()
        .first;

    switch (actualTypeElement.name.local) {
      case 'string':
        return UspValueType.string;
      case 'int':
        return UspValueType.int;
      case 'unsignedInt':
        return UspValueType.unsignedInt;
      case 'long':
        return UspValueType.long;
      case 'unsignedLong':
        return UspValueType.unsignedLong;
      case 'boolean':
        return UspValueType.boolean;
      case 'dateTime':
        return UspValueType.dateTime;
      case 'base64':
        return UspValueType.base64;
      case 'hexBinary':
        return UspValueType.hexBinary;
      default:
        return UspValueType.string;
    }
  }

  dynamic _getDefaultValue(UspValueType type) {
    switch (type) {
      case UspValueType.boolean:
        return false;
      case UspValueType.int:
      case UspValueType.unsignedInt:
      case UspValueType.long:
      case UspValueType.unsignedLong:
        return 0;
      default:
        return "";
    }
  }
}
