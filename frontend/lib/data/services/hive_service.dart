import 'package:hive_flutter/hive_flutter.dart';

class HiveService {
  static const String tasksBoxName = 'tasks_box';
  static const String draftBoxName = 'draft_box';

  late final Box<Map> _tasksBox;
  late final Box<Map> _draftBox;

  Future<void> init({String? path}) async {
    if (path == null) {
      await Hive.initFlutter();
    } else {
      Hive.init(path);
    }
    _tasksBox = await Hive.openBox<Map>(tasksBoxName);
    _draftBox = await Hive.openBox<Map>(draftBoxName);
  }

  Box<Map> get tasksBox => _tasksBox;
  Box<Map> get draftBox => _draftBox;
}
