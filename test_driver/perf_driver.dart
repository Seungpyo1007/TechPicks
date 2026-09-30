import 'dart:convert';
import 'dart:io';

import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver(
  responseDataCallback: (data) async {
    if (data == null) return;
    final dir = Directory('build/perf')..createSync(recursive: true);
    for (final entry in data.entries) {
      File('${dir.path}/${entry.key}.json').writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert(entry.value),
      );
    }
  },
);
