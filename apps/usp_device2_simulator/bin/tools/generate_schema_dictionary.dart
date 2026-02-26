import 'dart:io';
import 'dart:convert';
import 'package:usp_device2_simulator/infrastructure/schema/xml_schema_loader.dart';
import 'package:usp_device2_simulator/domain/entities/usp_object.dart';
import 'package:usp_device2_simulator/domain/entities/usp_parameter.dart';

void main() async {
  const xmlPath = 'test/data/tr-181-2-20-0-cwmp-full.xml';
        const jsonPath = 'apps/usp_flutter_client/assets/schema_dictionary.json'; // Directly generate to client project
  
        print('📦 Loading XML...');
        final tree = await XmlSchemaLoader().loadSchema(await File(xmlPath).readAsString());
  
        final dictionary = <String, dynamic>{};
        _extractConstraints(tree.root, dictionary);
  
        print('💾 Saving Dictionary to $jsonPath...');
        await File(jsonPath).writeAsString(jsonEncode(dictionary));
        print('✅ Done! Extracted ${dictionary.length} definitions.');
      }
void _extractConstraints(UspObject object, Map<String, dynamic> dict) {
  // 1. Process parameters
  for (final child in object.children.values) {
    if (child is UspParameter) {
      // Only output meaningful constraints to save size
      final c = child.constraints;
      if (c.min != null || c.max != null || c.maxLength != null || c.enumeration.isNotEmpty) {
        
        // Keep {i} in the path, as this is a generic definition
        // e.g., "Device.WiFi.Radio.{i}.Channel"
        dict[child.path.fullPath] = {
          if (c.min != null) 'min': c.min,
          if (c.max != null) 'max': c.max,
          if (c.maxLength != null) 'len': c.maxLength,
          if (c.enumeration.isNotEmpty) 'enum': c.enumeration,
          // Also include the type for easier offline checking by the Client
          'type': child.value.type.name,
        };
      }
    }
    else if (child is UspObject) {
      _extractConstraints(child, dict);
    }
  }
}