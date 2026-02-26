import 'dart:async';
import 'package:usp_device2_simulator/domain/entities/usp_node.dart';
import 'package:usp_device2_simulator/domain/entities/usp_object.dart';
import 'package:usp_protocol_common/usp_protocol_common.dart';
import 'package:usp_device2_simulator/domain/events/notifications.dart';
import 'package:usp_device2_simulator/domain/entities/usp_parameter.dart';
import 'package:json_annotation/json_annotation.dart';

part 'device_tree.g.dart';

@JsonSerializable(explicitToJson: true)
class DeviceTree {
  final UspObject root;
  
  @JsonKey(includeFromJson: false, includeToJson: false)
  final _notificationController = StreamController<Notification>.broadcast();

  DeviceTree({required this.root});

  factory DeviceTree.fromJson(Map<String, dynamic> json) => _$DeviceTreeFromJson(json);
  Map<String, dynamic> toJson() => _$DeviceTreeToJson(this);

  @JsonKey(includeFromJson: false, includeToJson: false)
  Stream<Notification> get notifications => _notificationController.stream;

  void _publishNotification(Notification notification) {
    _notificationController.add(notification);
  }

  UspNode? getNode(String path) {
    final uspPath = UspPath.parse(path);
    return _findNodeByPath(root, uspPath);
  }

  // --- Helpers ---

  UspNode? _findNodeByPath(UspObject currentObject, UspPath targetPath) {
    if (currentObject.path == targetPath) {
      return currentObject;
    }
    for (final child in currentObject.children.values) {
      if (targetPath.fullPath.startsWith(child.path.fullPath)) {
        if (child is UspObject) {
          final foundNode = _findNodeByPath(child, targetPath);
          if (foundNode != null) {
            return foundNode;
          }
        } else if (child.path == targetPath) {
          return child;
        }
      }
    }
    return null;
  }

  /// Immutable Update: Recursively replaces a node.
  UspObject _replaceNodeInTree(UspObject currentObject, UspPath targetPath, UspNode newNode) {
    // 1. Find the target parent node (or the target node itself, depending on the call context)
    if (currentObject.path == targetPath) {
      final newChildren = Map<String, UspNode>.from(currentObject.children);
      // If adding/updating a child node, the newNode's name is the Key
      newChildren[newNode.name] = newNode;
      
      return UspObject(
        path: currentObject.path,
        children: newChildren,
        isMultiInstance: currentObject.isMultiInstance,
        nextInstanceId: currentObject.nextInstanceId,
        minEntries: currentObject.minEntries, 
        attributes: currentObject.attributes,
      );
    }

    // 2. Recursive search
    final newChildren = <String, UspNode>{};
    bool childrenChanged = false;

    for (final entry in currentObject.children.entries) {
      final childName = entry.key;
      final childNode = entry.value;

      if (targetPath.fullPath.startsWith(childNode.path.fullPath) && childNode is UspObject) {
        final updatedChild = _replaceNodeInTree(childNode, targetPath, newNode);
        if (updatedChild != childNode) {
          newChildren[childName] = updatedChild;
          childrenChanged = true;
        } else {
          newChildren[childName] = childNode;
        }
      } else {
        newChildren[childName] = childNode;
      }
    }

    if (childrenChanged) {
      return UspObject(
        path: currentObject.path,
        children: newChildren,
        isMultiInstance: currentObject.isMultiInstance,
        nextInstanceId: currentObject.nextInstanceId,
        minEntries: currentObject.minEntries,
        attributes: currentObject.attributes,
      );
    }
    return currentObject;
  }

  /// Immutable Update: Recursively deletes a node.
  UspObject _removeNodeInTree(UspObject currentObject, UspPath targetPath, String nodeToRemoveName) {
    if (currentObject.path == targetPath) {
      final newChildren = Map<String, UspNode>.from(currentObject.children);
      if (!newChildren.containsKey(nodeToRemoveName)) {
        throw UspException(7002, 'Object not found for deletion: ${targetPath.fullPath}.$nodeToRemoveName');
      }
      newChildren.remove(nodeToRemoveName);
      
      return UspObject(
        path: currentObject.path,
        children: newChildren,
        isMultiInstance: currentObject.isMultiInstance,
        nextInstanceId: currentObject.nextInstanceId,
        minEntries: currentObject.minEntries,
        attributes: currentObject.attributes,
      );
    }

    final newChildren = <String, UspNode>{};
    bool childrenChanged = false;

    for (final entry in currentObject.children.entries) {
      final childName = entry.key;
      final childNode = entry.value;

      if (targetPath.fullPath.startsWith(childNode.path.fullPath) && childNode is UspObject) {
        final updatedChild = _removeNodeInTree(childNode, targetPath, nodeToRemoveName);
        if (updatedChild != childNode) {
          newChildren[childName] = updatedChild;
          childrenChanged = true;
        } else {
          newChildren[childName] = childNode;
        }
      } else {
        newChildren[childName] = childNode;
      }
    }

    if (childrenChanged) {
      return UspObject(
        path: currentObject.path,
        children: newChildren,
        isMultiInstance: currentObject.isMultiInstance,
        nextInstanceId: currentObject.nextInstanceId,
        minEntries: currentObject.minEntries,
        attributes: currentObject.attributes,
      );
    }
    return currentObject;
  }

  // --- Public Methods ---

  DeviceTree updateNode(UspNode updatedNode) {
    if (updatedNode.path == root.path) {
      if (updatedNode is UspObject) {
        return DeviceTree(root: updatedNode);
      }
      throw UspException(7001, "Cannot replace root with a non-UspObject node.");
    }

    final oldNode = _findNodeByPath(root, updatedNode.path);
    if (oldNode == null) {
      throw UspException(7002, 'Node not found for update: ${updatedNode.path.fullPath}');
    }
    
    // Note: UspPath.parent is Nullable, but since we excluded Root, we can use ! here
    final newRoot = _replaceNodeInTree(root, updatedNode.path.parent!, updatedNode);

    if (oldNode is UspParameter && updatedNode is UspParameter) {
      _publishNotification(ValueChangeNotification(
        path: updatedNode.path, 
        oldValue: oldNode.value, 
        newValue: updatedNode.value
      ));
    }
    return DeviceTree(root: newRoot);
  }

  DeviceTree addObject(UspPath parentPath, UspObject newObject) {
    if (parentPath == root.path) {
      final newChildren = Map<String, UspNode>.from(root.children);
      newChildren[newObject.name] = newObject;
      
      final newRoot = UspObject(
        path: root.path,
        children: newChildren,
        isMultiInstance: root.isMultiInstance,
        nextInstanceId: root.nextInstanceId,
        minEntries: root.minEntries,
        attributes: root.attributes,
      );
      _publishNotification(ObjectCreationNotification(path: newObject.path));
      return DeviceTree(root: newRoot);
    }
    
    final newRoot = _replaceNodeInTree(root, parentPath, newObject);
    
    if (newRoot == root) {
      // If Root didn't change, it's likely the Parent wasn't found.
      throw UspException(7002, 'Parent path not found for adding object: ${parentPath.fullPath}');
    }
    _publishNotification(ObjectCreationNotification(path: newObject.path));
    return DeviceTree(root: newRoot);
  }

  DeviceTree deleteObject(UspPath objectPath) {
    if (objectPath == root.path) {
      throw UspException(7006, 'Cannot delete the root object of the DeviceTree.');
    }
    
    // Parent will not be null since Root is excluded
    final parentPath = objectPath.parent!;
    final objectName = objectPath.name; // Using UspPath.name

    final newRoot = _removeNodeInTree(root, parentPath, objectName);
    
    _publishNotification(ObjectDeletionNotification(path: objectPath));
    return DeviceTree(root: newRoot);
  }
}