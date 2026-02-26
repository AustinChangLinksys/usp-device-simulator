import 'dart:io';

import 'package:test/test.dart';
import 'package:usp_device2_simulator/infrastructure/schema/xml_schema_loader.dart';

void main() {
  group('XmlSchemaLoader Performance', () {
    test('should load the full schema within an acceptable time limit', () async {
      final loader = XmlSchemaLoader();
      final xmlContent = await File(
        'test/data/tr-181-2-20-0-usp-full.xml',
      ).readAsString();

      final stopwatch = Stopwatch()..start();
      await loader.loadSchema(xmlContent);
      stopwatch.stop();

      print('Schema loaded in ${stopwatch.elapsedMilliseconds} ms');

      // SC-004: The schema loading time must not increase by more than 15% compared to the baseline
      // Since we don't have a baseline, we set a generous absolute limit for now.
      // This can be adjusted once a baseline is established.
      expect(
        stopwatch.elapsed.inSeconds,
        lessThan(5),
        reason: 'Schema loading should be reasonably fast.',
      );
    });
  });
}
