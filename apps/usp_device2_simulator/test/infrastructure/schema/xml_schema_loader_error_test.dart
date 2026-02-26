import 'package:test/test.dart';
import 'package:usp_device2_simulator/infrastructure/schema/xml_schema_loader.dart';
import 'package:xml/xml.dart';
import 'package:usp_protocol_common/usp_protocol_common.dart'; // Import UspException

void main() {
  group('XmlSchemaLoader Error Handling', () {
    late XmlSchemaLoader loader;

    setUp(() {
      loader = XmlSchemaLoader();
    });

    test('should throw an exception for malformed XML', () async {
      final invalidXmlContent = '''
<device:device>
  <device:object name="DeviceInfo">
    <device:parameter name="Manufacturer">
      <base:string></base:string>
    </device:parameter>
  </device:object>
'''; // Missing closing tags

      expect(
        () async => await loader.loadSchema(invalidXmlContent),
        throwsA(
          isA<XmlException>(),
        ), // The `xml` package throws XmlException (superclass of XmlParserException, XmlTagException)
      );
    });

    test(
      'should throw an exception if root <document> element is missing',
      () async {
        final invalidXmlContent = '''
<root>
  <model>
    <object name="DeviceInfo.">
      <parameter name="Manufacturer">
        <syntax><string/></syntax>
      </parameter>
    </object>
  </model>
</root>
'''; // Missing <dm:document>

        expect(
          () async => await loader.loadSchema(invalidXmlContent),
          throwsA(
            isA<UspException>().having((e) => e.errorCode, 'errorCode', 7001),
          ),
        );
      },
    );

    test(
      'should throw an exception if <model> element is missing within <document>',
      () async {
        final invalidXmlContent = '''
<dm:document xmlns:dm="urn:broadband-forum-org:cwmp:datamodel-1-8">
  <root>
    <object name="DeviceInfo.">
      <parameter name="Manufacturer">
        <syntax><string/></syntax>
      </parameter>
    </object>
  </root>
</dm:document>
'''; // Missing <model>

        expect(
          () async => await loader.loadSchema(invalidXmlContent),
          throwsA(
            isA<UspException>().having((e) => e.errorCode, 'errorCode', 7001),
          ),
        );
      },
    );
  });
}
