import '../models/task.dart';
import '../services/hive_service.dart';

class TaskRepository {
  const TaskRepository(this._hiveService);

  final HiveService _hiveService;

  List<Task> getTasks() {
    final values = _hiveService.tasksBox.values.toList();
    return values
        .map((entry) => Task.fromJson(Map<dynamic, dynamic>.from(entry)))
        .toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
  }

  Future<void> upsertTask(Task task) {
    return _hiveService.tasksBox.put(task.id, task.toJson());
  }

  Future<void> deleteTask(String id) {
    return _hiveService.tasksBox.delete(id);
  }

  TaskDraft? getDraft() {
    final map = _hiveService.draftBox.get('task_form_draft');
    if (map == null) {
      return null;
    }
    return TaskDraft.fromJson(Map<dynamic, dynamic>.from(map));
  }

  Future<void> saveDraft(TaskDraft draft) {
    return _hiveService.draftBox.put('task_form_draft', draft.toJson());
  }

  Future<void> clearDraft() {
    return _hiveService.draftBox.delete('task_form_draft');
  }
}
