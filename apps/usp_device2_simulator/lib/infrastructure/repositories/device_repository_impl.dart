import 'dart:async';
import 'dart:io';
import 'package:usp_device2_simulator/domain/entities/device_tree.dart';
import 'package:usp_device2_simulator/domain/entities/usp_node.dart';
import 'package:usp_device2_simulator/domain/entities/usp_object.dart';
import 'package:usp_device2_simulator/domain/entities/usp_parameter.dart';
import 'package:usp_device2_simulator/domain/entities/usp_command_node.dart';
import 'package:usp_device2_simulator/domain/events/notifications.dart';
import 'package:usp_device2_simulator/infrastructure/commands/command_registry.dart';
import 'package:usp_protocol_common/usp_protocol_common.dart';
import 'package:usp_device2_simulator/domain/repositories/i_device_repository.dart';
import 'package:usp_device2_simulator/infrastructure/persistence/i_persistence_service.dart';
import 'package:usp_device2_simulator/infrastructure/schema/i_schema_loader.dart';

class DeviceRepositoryImpl implements IDeviceRepository {
  DeviceTree _deviceTree;
  final PathResolver _pathResolver;
  final IPersistenceService _persistenceService;

  DeviceRepositoryImpl(this._deviceTree, this._persistenceService)
    : _pathResolver = PathResolver();

  static Future<DeviceRepositoryImpl> create(
    IPersistenceService persistenceService,
    ISchemaLoader schemaLoader,
    String schemaFilePath,
  ) async {
    // 1. Try to load from persistence
    DeviceTree? deviceTree = await persistenceService.load();
    if (deviceTree != null) {
      return DeviceRepositoryImpl(deviceTree, persistenceService);
    }

    // 2. If persistence fails, load from schema
    final file = File(schemaFilePath);
    final xmlContent = await file.readAsString();
    final loadedSchemaTree = await schemaLoader.loadSchema(xmlContent);

    // 3. Create the repository
    return DeviceRepositoryImpl(loadedSchemaTree, persistenceService);
  }

  // Expose the notifications stream from DeviceTree
  Stream<Notification> get notifications => _deviceTree.notifications;

  @override
  DeviceTree getDeviceTree() => _deviceTree;

  // Implements updateTree - This is the method that addObject needs to call, responsible for updating state and persistence
  @override
  Future<void> updateTree(DeviceTree newTree) async {
    _deviceTree = newTree;
    await _persistenceService.save(_deviceTree);
  }

  @override
  Future<Map<UspPath, UspValue>> getParameterValue(UspPath path) async {
    final nodes = _pathResolver.resolve<UspNode>(_deviceTree.root, path);

    if (nodes.isEmpty) {
      throw UspException(7002, 'Path not found: ${path.fullPath}');
    }

    final result = <UspPath, UspValue>{};

    for (final node in nodes) {
      if (node is UspParameter) {
        result[node.path] = node.value;
      } else if (node is UspObject) {
        _collectAllParameters(node, result);
      }
    }

    return result;
  }

  void _collectAllParameters(UspObject object, Map<UspPath, UspValue> result) {
    for (final child in object.children.values) {
      if (child.name.contains('{i}')) {
        continue;
      }

      if (child is UspParameter) {
        result[child.path] = child.value;
      } else if (child is UspObject) {
        _collectAllParameters(child, result);
      }
    }
  }

  @override
  Future<void> setParameterValue(UspPath path, UspValue value) async {
    final nodes = _pathResolver.resolve<UspNode>(_deviceTree.root, path);
    if (nodes.isEmpty) {
      throw UspException(7002, 'Path not found: ${path.fullPath}');
    }

    for (final node in nodes) {
      if (node is UspParameter) {
        if (node.isWritable) {
          final newParam = UspParameter(
            path: node.path,
            value: value,
            isWritable: node.isWritable,
            attributes: node.attributes,
          );

          // Use updateTree to handle updates and saving uniformly
          final newTree = _deviceTree.updateNode(newParam);
          await updateTree(newTree);
        } else {
          throw UspException(
            7003,
            'Parameter is not writable: ${path.fullPath}',
          );
        }
      }
    }
  }

  @override
  Future<UspPath> addObject(
    UspPath parentPath,
    String objectTemplateName, {
    int? instanceId,
  }) async {
    DeviceTree currentTree = getDeviceTree();

    final int newInstanceId =
        instanceId ?? DateTime.now().millisecondsSinceEpoch;

    final newObjectPath = UspPath.parse(
      '${parentPath.fullPath}.$newInstanceId',
    );

    final parentNodes = _pathResolver.resolve<UspNode>(
      currentTree.root,
      parentPath,
    );
    if (parentNodes.isEmpty || parentNodes.first is! UspObject) {
      throw UspException(
        7002,
        "Parent object not found: ${parentPath.fullPath}",
      );
    }
    final parentNode = parentNodes.first as UspObject;

    final templateNode = parentNode.children['{i}'];

    if (templateNode == null) {
      throw UspException(
        7002,
        "Template '{i}' not found under ${parentPath.fullPath}. Cannot instantiate.",
      );
    }
    if (templateNode is! UspObject) {
      throw UspException(7003, "Template '{i}' is not an object.");
    }

    final newInstanceNode = _createInstanceFromTemplate(
      templateNode,
      newObjectPath,
      '$newInstanceId',
    );

    final newTree = currentTree.addObject(parentPath, newInstanceNode);

    // Now it can be called normally here
    await updateTree(newTree);

    return newObjectPath;
  }

  @override
  Future<void> deleteObject(UspPath objectPath) async {
    final newTree = _deviceTree.deleteObject(objectPath);
    // Use updateTree
    await updateTree(newTree);
  }

  @override
  Future<Map<String, UspValue>> operate(
    UspPath commandPath,
    Map<String, UspValue> inputArgs,
  ) async {
    // 1. Find the Command Node
    final nodes = _pathResolver.resolve<UspNode>(_deviceTree.root, commandPath);

    if (nodes.isEmpty) {
      throw UspException(7002, 'Command not found: ${commandPath.fullPath}');
    }

    final node = nodes.first;

    // 2. Check if it's a Command Node
    if (node is UspCommandNode) {
      // 3. Execute the command (Command Node should have execution logic or delegate it)
      // Note: This synchronously waits for the "start result", not for "asynchronous operation completion".
      // According to USP, OperateResponse usually returns OutputArgs (for synchronous commands)
      // or empty (for asynchronous commands, which will send Notify later).

      // Call the execute method of CommandNode (we need to ensure CommandNode has this method)
      // Assuming execute returns Future<Map<String, dynamic>>
      final rawResult = await node.execute(inputArgs);

      // Convert back to UspValue
      return rawResult.map(
        (k, v) => MapEntry(k, UspValue(v, UspValueType.string)),
      ); // Simplified handling, depends on actual type
    } else {
      throw UspException(
        7004,
        'Path is not a command: ${commandPath.fullPath}',
      );
    }
  }

  @override
  // Return type changed to UspSupportedDMObject (i.e., Map<String, UspObjectDefinition>)
  Future<UspSupportedDMObject> getSupportedDM(UspPath path) async {
    final results = <String, UspObjectDefinition>{};

    final nodes = _pathResolver.resolve<UspNode>(_deviceTree.root, path);

    if (nodes.isEmpty) {
      throw UspException(7002, 'Path not found: ${path.fullPath}');
    }

    for (final node in nodes) {
      if (node is UspObject) {
        // Call recursive collection function
        _collectObjectDefinitionsRecursively(node, results);
      }
      // If a specific Command is queried, it can also be handled
      else if (node is UspCommandNode) {
        // Special handling for Command, or ignore
      }
    }

    return results;
  }

  /// Recursively collects definitions of all descendant objects.
  void _collectObjectDefinitionsRecursively(
    UspObject object,
    Map<String, UspObjectDefinition> results,
  ) {
    // 1. Create the definition of the current object (reusing original logic, but encapsulated)
    final def = _buildSingleObjectDefinition(object);

    // 2. Store in Map (Key is the full path)
    results[object.path.fullPath] = def;

    // 3. [Crucial] Recursively traverse child nodes
    for (final child in object.children.values) {
      if (child is UspObject) {
        _collectObjectDefinitionsRecursively(child, results);
      }
    }
  }

  /// Converts a single UspObject to UspObjectDefinition (refactoring of original logic)
  UspObjectDefinition _buildSingleObjectDefinition(UspObject node) {
    final supportedCommands = <String, UspCommandDefinition>{};
    final supportedParams = <String, UspParamDefinition>{};

    for (final child in node.children.values) {
      if (child is UspCommandNode) {
        final cmdDef = UspCommandDefinition(
          name: child.name,
          inputArgs: child.inputArgs,
          outputArgs: child.outputArgs,
          isAsync: child.isAsync,
        );
        supportedCommands[child.name] = cmdDef;
      } else if (child is UspParameter) {
        final paramDef = UspParamDefinition(
          name: child.name,
          type: child.value.type,
          isWritable: child.isWritable,
          constraints: child.constraints,
        );
        supportedParams[child.name] = paramDef;
      }
    }

    return UspObjectDefinition(
      path: node.path.fullPath,
      isMultiInstance: node.isMultiInstance,
      // Access control logic can be adjusted as needed
      access: node.isMultiInstance ? "ReadWrite" : "ReadOnly",
      supportedCommands: supportedCommands,
      supportedParams: supportedParams,
    );
  }

  @override
  Future<void> updateInternally(UspPath path, UspValue value) async {
    final nodes = _pathResolver.resolve<UspNode>(_deviceTree.root, path);
    if (nodes.isEmpty) {
      throw UspException(7002, 'Path not found: ${path.fullPath}');
    }

    for (final node in nodes) {
      if (node is UspParameter) {
        final newParam = UspParameter(
          path: node.path,
          value: value,
          isWritable: node.isWritable,
          attributes: node.attributes,
        );
        // Internal update does not call updateTree (does not save to file), only updates memory state
        _deviceTree = _deviceTree.updateNode(newParam);
      }
    }
  }

  UspObject _createInstanceFromTemplate(
    UspObject template,
    UspPath newPath,
    String newName,
  ) {
    final newChildren = <String, UspNode>{};

    for (final childEntry in template.children.entries) {
      final childNode = childEntry.value;
      final childName = childNode.name;
      final childPath = UspPath.parse('${newPath.fullPath}.$childName');

      if (childNode is UspParameter) {
        newChildren[childName] = childNode.copyWith(path: childPath);
      } else if (childNode is UspObject) {
        newChildren[childName] = _createInstanceFromTemplate(
          childNode,
          childPath,
          childName,
        );
      }
    }

    return UspObject(
      path: newPath,
      isMultiInstance: true,
      children: newChildren,
      attributes: template.attributes,
    );
  }

  @override
  Future<void> injectCommandImplementations(CommandRegistry registry) async {
    print('💉 Injecting ${registry.all.length} command implementations...');

    int successCount = 0;

    // Iterate through each implementation in the Registry
    for (final entry in registry.all.entries) {
      final pathStr = entry.key;
      final executor = entry.value;
      final path = UspPath.parse(pathStr);

      // 1. Find this node in the tree (it should have been created by the XML Loader)
      final nodes = _pathResolver.resolve<UspNode>(_deviceTree.root, path);

      if (nodes.isNotEmpty && nodes.first is UspCommandNode) {
        final commandNode = nodes.first as UspCommandNode;

        // 2. Create a new Node and inject the executor
        // Note: We retain the original metadata (input/output args), only injecting the behavior.
        final newCommandNode = commandNode.copyWith(executor: executor);

        // 3. Update the tree (using DeviceTree's Immutable Update)
        // We directly operate on _deviceTree here, as this is during initialization.
        _deviceTree = _deviceTree.updateNode(newCommandNode);
        successCount++;
      } else {
        print(
          '   ⚠️ Warning: Implementation registered for "$pathStr", but node not found in Schema.',
        );
      }
    }

    print('✅ Injected $successCount commands successfully.');
  }

  @override
  Future<List<UspInstanceResult>> getInstances(
    UspPath path,
    bool firstLevelOnly,
  ) async {
    final results = <UspInstanceResult>[];

    // 1. Find the target node of the request (e.g., "Device.WiFi.Radio.")
    final nodes = _pathResolver.resolve<UspNode>(_deviceTree.root, path);

    if (nodes.isEmpty) {
      // According to USP, a non-existent path usually throws an error
      throw UspException(7002, 'Path not found: ${path.fullPath}');
    }

    // 2. For each found node, collect its child objects
    for (final node in nodes) {
      if (node is UspObject) {
        _collectInstancesRecursively(node, results, firstLevelOnly);
      }
    }

    return results;
  }

  /// Recursive helper to collect instances.
  void _collectInstancesRecursively(
    UspObject parent,
    List<UspInstanceResult> results,
    bool firstLevelOnly,
  ) {
    // Iterate through all child nodes
    for (final child in parent.children.values) {
      // [Filter 1] Only process objects (ignore parameters and commands)
      if (child is UspObject) {
        // [Filter 2] Ignore templates (Template {i})
        // GetInstances is for fetching "real existing entities"
        if (child.name.contains('{i}')) continue;

        // 1. Add to results
        results.add(
          UspInstanceResult(
            child.path.fullPath,
            uniqueKeys: _extractUniqueKeys(child),
          ),
        );

        // 2. If not only the first level, recursively search further
        if (!firstLevelOnly) {
          _collectInstancesRecursively(child, results, false);
        }
      }
    }
  }

  /// Helper to extract Unique Keys
  /// Used to identify key parameters for multi-instance objects (e.g., Alias, Name)
  Map<String, String> _extractUniqueKeys(UspObject object) {
    final keys = <String, String>{};

    // In a full implementation, this should query the <uniqueKey> list defined in the Schema.
    // However, in the PoC phase, we use "convention-based" keys (Alias, Name, ID).
    // Or iterate all parameters (not recommended, too slow).

    const candidateKeys = ['Alias', 'Name', 'ID', 'BSSID', 'MACAddress'];

    for (final key in candidateKeys) {
      final paramNode = object.children[key];
      if (paramNode is UspParameter) {
        keys[key] = paramNode.value.value.toString();
      }
    }

    return keys;
  }
}
