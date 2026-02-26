import 'package:test/test.dart';
import 'package:usp_device2_simulator/domain/entities/usp_command_node.dart';
import 'package:usp_device2_simulator/infrastructure/schema/xml_schema_loader.dart';
import 'package:usp_protocol_common/usp_protocol_common.dart';

void main() {
  group('XmlSchemaLoader Command Parsing', () {
    test('should correctly parse command nodes and their arguments from a mock schema', () async {
      final loader = XmlSchemaLoader();
      const mockXmlContent = '''
        <document>
          <model name="urn:broadband-forum-org:tr-181-2-20-0" spec="urn:broadband-forum-org:tr-106-1-2" isAbstract="false">
            <object name="Device." access="readOnly" minEntries="1" maxEntries="1">
              <object name="Device.Test." access="readOnly" minEntries="1" maxEntries="1">
                <command name="MyCommand()" commandType="asynchronous">
                  <input>
                    <parameter name="InArg1">
                      <syntax><string/></syntax>
                    </parameter>
                  </input>
                  <output>
                    <parameter name="OutArg1">
                      <syntax><unsignedInt/></syntax>
                    </parameter>
                  </output>
                </command>
              </object>
            </object>
          </model>
        </document>
      ''';

      final deviceTree = await loader.loadSchema(mockXmlContent);

      final commandNode = deviceTree.getNode('Device.Test.MyCommand()');
      expect(commandNode, isA<UspCommandNode>());

      final command = commandNode as UspCommandNode;
      expect(command.isParameter, isFalse);
      expect(command.isAsync, isTrue);
      
      expect(command.inputArgs, isNotEmpty);
      expect(command.inputArgs.length, 1);
      final inArg = command.inputArgs['InArg1'];
      expect(inArg, isNotNull);
      expect(inArg!.name, 'InArg1');
      expect(inArg.type, UspValueType.string);

      expect(command.outputArgs, isNotEmpty);
      expect(command.outputArgs.length, 1);
      final outArg = command.outputArgs['OutArg1'];
      expect(outArg, isNotNull);
      expect(outArg!.name, 'OutArg1');
      expect(outArg.type, UspValueType.unsignedInt);
    });
  });
}