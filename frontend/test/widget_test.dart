import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:task_management_app/data/services/hive_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Hive can initialize in test environment', () async {
    final root = await Directory.systemTemp.createTemp('task_mgmt_hive_test_');
    await root.create(recursive: true);
    final service = HiveService();
    await service.init(path: root.path);
    expect(service.tasksBox.isOpen, isTrue);
    expect(service.draftBox.isOpen, isTrue);
    await service.tasksBox.clear();
    await service.draftBox.clear();
    await Hive.close();
    await root.delete(recursive: true);
  });
}
