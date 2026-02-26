import 'dart:io';

import 'package:test/test.dart';
import 'package:usp_device2_simulator/domain/entities/usp_node.dart';
import 'package:usp_device2_simulator/domain/entities/usp_object.dart';
import 'package:usp_device2_simulator/domain/entities/usp_parameter.dart';
import 'package:usp_protocol_common/usp_protocol_common.dart';
import 'package:usp_device2_simulator/infrastructure/schema/xml_schema_loader.dart';

void main() {
  group('XmlSchemaLoader', () {
    late XmlSchemaLoader loader;

    setUp(() {
      loader = XmlSchemaLoader();
    });

    test(
      'should parse a valid XML schema and build DeviceTree correctly',
      () async {
        final xmlContent = '''
<?xml version="1.0" encoding="UTF-8"?>
<dm:document xmlns:dm="urn:broadband-forum-org:cwmp:datamodel-1-8"
             xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
             spec="urn:broadband-forum-org:tr-181-2-16-0">

  <model name="Device:2.16">
    <object name="Device." access="readOnly" minEntries="1" maxEntries="1"/>

    <object name="Device.DeviceInfo." access="readOnly" minEntries="1" maxEntries="1">
      <parameter name="Manufacturer" access="readOnly">
        <syntax><string><size maxLength="64"/></string></syntax>
      </parameter>
      <parameter name="UpTime" access="readOnly">
        <syntax><unsignedInt/></syntax>
      </parameter>
    </object>

    <object name="Device.Time." access="readOnly" minEntries="1" maxEntries="1">
      <parameter name="Enable" access="readWrite">
        <syntax><boolean/></syntax>
      </parameter>
    </object>

    <object name="Device.IP." access="readOnly" minEntries="1" maxEntries="1"/>
    
    <object name="Device.IP.Interface.{i}." access="readWrite" minEntries="0" maxEntries="unbounded">
      <parameter name="Enable" access="readWrite">
        <syntax><boolean/></syntax>
      </parameter>
    </object>

    <object name="Device.WiFi." access="readOnly" minEntries="1" maxEntries="1"/>

    <object name="Device.WiFi.Radio.{i}." access="readWrite" minEntries="0" maxEntries="unbounded">
      <parameter name="Channel" access="readWrite">
         <syntax><unsignedInt/></syntax>
      </parameter>
    </object>

  </model>
</dm:document>
''';

        final deviceTree = await loader.loadSchema(xmlContent);

        // 1. Assertions for Root
        expect(deviceTree.root.name, 'Device');
        expect(
          deviceTree.root.children.keys,
          containsAll(['DeviceInfo', 'Time', 'IP', 'WiFi']),
        );

        // 2. Assertions for DeviceInfo (Static Object)
        final deviceInfo = deviceTree.root.children['DeviceInfo'] as UspObject;
        expect(deviceInfo.name, 'DeviceInfo');
        expect(deviceInfo.path.fullPath, 'Device.DeviceInfo');
        expect(deviceInfo.isMultiInstance, isFalse);

        final manufacturer =
            deviceInfo.children['Manufacturer'] as UspParameter;
        expect(manufacturer.value.type, UspValueType.string);
        expect(manufacturer.isWritable, isFalse);

        // 3. Assertions for IP Interface (Multi-Instance Hierarchy)
        final ipObject = deviceTree.root.children['IP'] as UspObject;

        expect(
          ipObject.children.keys,
          contains('Interface'),
          reason: 'Should contain the Table object',
        );
        final interfaceTable = ipObject.children['Interface'] as UspObject;
        expect(
          interfaceTable.isMultiInstance,
          isFalse,
          reason: 'Table object itself is singleton',
        );

        expect(
          interfaceTable.children.keys,
          contains('{i}'),
          reason: 'Table should contain the {i} template',
        );
        final interfaceRow = interfaceTable.children['{i}'] as UspObject;
        expect(
          interfaceRow.isMultiInstance,
          isTrue,
          reason: 'Row template is multi-instance',
        );
        expect(interfaceRow.path.fullPath, 'Device.IP.Interface.{i}');

        // Validate that parameters are correctly mounted under {i}
        final interfaceEnable = interfaceRow.children['Enable'] as UspParameter;
        expect(interfaceEnable.name, 'Enable');
        expect(interfaceEnable.isWritable, isTrue);

        // 4. Assertions for WiFi Radio (Check Implied Parent Creation)
        final wifiObject = deviceTree.root.children['WiFi'] as UspObject;
        expect(wifiObject.children.keys, contains('Radio'));

        final radioTable = wifiObject.children['Radio'] as UspObject;
        expect(radioTable.children.keys, contains('{i}'));

        final radioRow = radioTable.children['{i}'] as UspObject;
        final radioChannel = radioRow.children['Channel'] as UspParameter;
        expect(radioChannel.value.type, UspValueType.unsignedInt);
      },
    );

    test(
      'should load FULL TR-181 schema within 2 seconds and verify structure',
      () async {
        // 1. Act: Load Schema
        final xmlSchemaContent = await File(
          'test/data/tr-181-2-20-0-usp-full.xml',
        ).readAsString();
        final schemaLoader = XmlSchemaLoader();

        // Start timer (even though flutter_test has a timeout, we print the actual elapsed time)
        final stopwatch = Stopwatch()..start();
        final deviceTree = await schemaLoader.loadSchema(xmlSchemaContent);
        stopwatch.stop();
        // print(
        //   '⏱️ Full Schema Parsing took: ${stopwatch.elapsedMilliseconds} ms (T060 Performance Test)',
        // );

        // 2. Prepare for Assertions
        final pathResolver = PathResolver();

        // Helper to get a node easily
        dynamic getNode(String path) {
          final nodes = pathResolver.resolve<UspNode>(
            deviceTree.root,
            UspPath.parse(path),
          );
          expect(nodes, isNotEmpty, reason: 'Critical Path not found: $path');
          return nodes.first;
        }

        // --- Assertion 1: Root & Major Components (Breadth) ---
        // Verify if the root node and major first-level modules exist
        expect(deviceTree.root.name, 'Device');
        expect(
          deviceTree.root.children.keys,
          containsAll([
            'DeviceInfo',
            'Time',
            'UserInterface',
            'IP',
            'DNS',
            'WiFi',
            'USB',
            'Ethernet',
            'Reboot()',
            'FactoryReset()',
            'SelfTestDiagnostics()',
            'PacketCaptureDiagnostics()',
          ]),
        );

        // --- Assertion 2: Static Parameter Properties (DeviceInfo) ---
        // Verify basic parameter properties (ReadOnly, String Type)
        final modelName =
            getNode('Device.DeviceInfo.ModelName') as UspParameter;
        expect(
          modelName.isWritable,
          isFalse,
          reason: 'ModelName should be ReadOnly',
        );
        expect(modelName.value.type, UspValueType.string);

        final upTime = getNode('Device.DeviceInfo.UpTime') as UspParameter;
        expect(upTime.value.type, UspValueType.unsignedInt);

        // 3. Assertions for IP Interface (Multi-Instance Hierarchy)
        // Path: Device.IP.Interface.{i}.

        // 3.1 Check Table Object
        final radioTable = getNode('Device.WiFi.Radio') as UspObject;
        expect(
          radioTable.isMultiInstance,
          isFalse,
          reason: 'Radio Table itself is a singleton',
        );
        expect(
          radioTable.children.keys,
          contains('{i}'),
          reason: 'Table must contain {i} template',
        );

        // 3.2 Check Template Object
        final radioTemplate = radioTable.children['{i}'] as UspObject;
        expect(
          radioTemplate.isMultiInstance,
          isTrue,
          reason: 'Radio {i} must be multi-instance template',
        );

        // 3.3 Check parameters under Template
        final channel =
            getNode('Device.WiFi.Radio.{i}.Channel') as UspParameter;
        expect(channel.value.type, UspValueType.unsignedInt);
        expect(
          channel.isWritable,
          isTrue,
          reason: 'Channel should be ReadWrite',
        );

        // 4. Assertions for Deeply Nested Tables (IP Interface)
        // Verify: Device.IP.Interface.{i}.IPv4Address.{i}.IPAddress
        // This tests the capability of recursive resolution

        final ipAddressParam =
            getNode('Device.IP.Interface.{i}.IPv4Address.{i}.IPAddress')
                as UspParameter;
        expect(ipAddressParam.name, 'IPAddress');
        expect(ipAddressParam.value.type, UspValueType.string);
        expect(ipAddressParam.isWritable, isTrue);

        // 5. Assertions for Specific Data Types
        // Verify if specific data types are parsed correctly
        final timeEnable = getNode('Device.Time.Enable') as UspParameter;
        expect(timeEnable.value.type, UspValueType.boolean);

        // Note: In some versions, Time is Device.Time.CurrentLocalTime, in others it is LocalTime
        // Assuming CurrentLocalTime (DateTime) here
        final localTime =
            getNode('Device.Time.CurrentLocalTime') as UspParameter;
        expect(localTime.value.type, UspValueType.dateTime);
      },
      timeout: const Timeout(Duration(seconds: 2)),
    );
  });
}
