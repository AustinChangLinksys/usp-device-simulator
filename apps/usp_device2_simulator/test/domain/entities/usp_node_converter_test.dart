import 'package:test/test.dart';
import 'package:usp_device2_simulator/domain/entities/usp_node.dart';
import 'package:usp_device2_simulator/domain/entities/usp_node_converter.dart';
import 'package:usp_device2_simulator/domain/entities/usp_object.dart';
import 'package:usp_device2_simulator/domain/entities/usp_parameter.dart';
import 'package:usp_protocol_common/usp_protocol_common.dart';

void main() {
  group('UspNodeConverter', () {
    const converter = UspNodeConverter();

    group('fromJson', () {
      test('should deserialize UspObject', () {
        final json = {
          '_type': 'UspObject',
          'path': {
            'segments': ['Device', ''],
          },
          'name': 'Device',
          'children': <String, dynamic>{},
        };
        final node = converter.fromJson(json);
        expect(node, isA<UspObject>());
        expect(node.path.fullPath, 'Device.');
      });

      test('should deserialize UspParameter<String>', () {
        final json = {
          '_type': 'UspParameter',
          'path': {
            'segments': ['Device', 'Name'],
          },
          'name': 'Name',
          'value': {'value': 'MyDevice', 'type': 'string'},
        };
        final node = converter.fromJson(json);
        expect(node, isA<UspParameter<String>>());
        final param = node as UspParameter<String>;
        expect(param.value.value, 'MyDevice');
      });

      test('should deserialize UspParameter<int>', () {
        final json = {
          '_type': 'UspParameter',
          'path': {
            'segments': ['Device', 'Count'],
          },
          'name': 'Count',
          'value': {'value': 10, 'type': 'int'},
        };
        final node = converter.fromJson(json);
        expect(node, isA<UspParameter<int>>());
        final param = node as UspParameter<int>;
        expect(param.value.value, 10);
      });

      test('should deserialize UspParameter<bool>', () {
        final json = {
          '_type': 'UspParameter',
          'path': {
            'segments': ['Device', 'Enabled'],
          },
          'name': 'Enabled',
          'value': {'value': true, 'type': 'boolean'},
        };
        final node = converter.fromJson(json);
        expect(node, isA<UspParameter<bool>>());
        final param = node as UspParameter<bool>;
        expect(param.value.value, true);
      });

      test('should throw UnimplementedError for unknown type', () {
        final json = {'_type': 'Unknown'};
        expect(
          () => converter.fromJson(json),
          throwsA(isA<UnimplementedError>()),
        );
      });
    });

    group('toJson', () {
      test('should serialize UspObject', () {
        final node = UspObject(path: UspPath.parse('Device.'));
        final json = converter.toJson(node);
        expect(json['_type'], 'UspObject');
        expect(json['path']['segments'], ['Device']);
      });

      test('should serialize UspParameter<String>', () {
        final node = UspParameter<String>(
          path: UspPath.parse('Device.Name'),
          value: UspValue('MyDevice', UspValueType.string),
        );
        final json = converter.toJson(node);
        expect(json['_type'], 'UspParameter');
        expect(json['value']['value'], 'MyDevice');
      });

      test('should serialize UspParameter<String> for base64 type', () {
        final node = UspParameter<String>(
          path: UspPath.parse('Device.Blob'),
          value: UspValue('SGVsbG8gV29ybGQ=', UspValueType.base64),
        );
        final json = converter.toJson(node);
        expect(json['_type'], 'UspParameter');
        expect(json['value']['value'], 'SGVsbG8gV29ybGQ=');
        expect(json['value']['type'], 'base64');
      });

      test('should serialize UspParameter<String> for hexBinary type', () {
        final node = UspParameter<String>(
          path: UspPath.parse('Device.Hash'),
          value: UspValue('0f2a', UspValueType.hexBinary),
        );
        final json = converter.toJson(node);
        expect(json['_type'], 'UspParameter');
        expect(json['value']['value'], '0f2a');
        expect(json['value']['type'], 'hexBinary');
      });

      test('should serialize UspParameter<int>', () {
        final node = UspParameter<int>(
          path: UspPath.parse('Device.Count'),
          value: UspValue(10, UspValueType.int),
        );
        final json = converter.toJson(node);
        expect(json['_type'], 'UspParameter');
        expect(json['value']['value'], 10);
      });

      test('should serialize UspParameter<bool>', () {
        final node = UspParameter<bool>(
          path: UspPath.parse('Device.Enabled'),
          value: UspValue(true, UspValueType.boolean),
        );
        final json = converter.toJson(node);
        expect(json['_type'], 'UspParameter');
        expect(json['value']['value'], true);
      });

      test('should throw UnimplementedError for unknown node type', () {
        final unknownNode = UnknownNode();
        expect(
          () => converter.toJson(unknownNode),
          throwsA(isA<UnimplementedError>()),
        );
      });
    });
  });
}

class UnknownNode extends UspNode {
  // [Fix 1] Remove name parameter.
  UnknownNode() : super(path: UspPath.parse('Unknown.'));

  // [Fix 2] Remove get children (base class no longer has this definition).
  // @override
  // Map<String, UspNode> get children => const {};

  @override
  UspNode? getChild(String name) {
    return null;
  }

  @override
  Iterable<UspNode> getAllChildren() {
    return const Iterable.empty();
  }

  @override
  bool get isMultiInstance => false;

  @override
  bool get isParameter => false;

  // [Fix 3] Add copyWith implementation (even for test nodes, it must conform to the interface).
  @override
  UnknownNode copyWith({UspPath? path, Map<String, dynamic>? attributes}) {
    // Test nodes usually have immutable state, so return a new instance or this.
    return UnknownNode();
  }
}
