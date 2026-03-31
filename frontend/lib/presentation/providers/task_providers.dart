import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/task.dart';
import '../../data/repositories/task_repository.dart';
import '../../data/services/hive_service.dart';

final hiveServiceProvider = Provider<HiveService>(
  (ref) => throw UnimplementedError('HiveService must be overridden at app root.'),
);

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepository(ref.read(hiveServiceProvider));
});

final allTasksProvider = AsyncNotifierProvider<TaskNotifier, List<Task>>(TaskNotifier.new);

class TaskNotifier extends AsyncNotifier<List<Task>> {
  TaskRepository get _repository => ref.read(taskRepositoryProvider);

  @override
  FutureOr<List<Task>> build() => _repository.getTasks();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async => _repository.getTasks());
  }

  Future<void> createTask({
    required String title,
    required String description,
    required DateTime startDateTime,
    required DateTime endDateTime,
    required TaskStatus status,
    String? blockedByTaskId,
  }) async {
    await Future.delayed(const Duration(seconds: 2));
    final task = Task(
      id: const Uuid().v4(),
      title: title,
      description: description,
      dueDate: endDateTime,
      startDateTime: startDateTime,
      endDateTime: endDateTime,
      status: status,
      blockedByTaskId: blockedByTaskId,
    );
    await _repository.upsertTask(task);
    await refresh();
  }

  Future<void> updateTask(Task task) async {
    await Future.delayed(const Duration(seconds: 2));
    await _repository.upsertTask(task);
    await refresh();
  }

  Future<void> deleteTask(String id) async {
    await _repository.deleteTask(id);
    await refresh();
  }

  Future<void> promoteDueTodoTasks() async {
    final current = state.asData?.value;
    if (current == null || current.isEmpty) {
      return;
    }

    final now = DateTime.now();
    final updates = <Task>[];

    for (final task in current) {
      if (task.status != TaskStatus.todo || task.startDateTime.isAfter(now)) {
        continue;
      }

      if (isTaskBlocked(task, current) || isTimeWindowBlocked(task, current)) {
        continue;
      }

      updates.add(task.copyWith(status: TaskStatus.inProgress));
    }

    if (updates.isEmpty) {
      return;
    }

    for (final updated in updates) {
      await _repository.upsertTask(updated);
    }

    await refresh();
  }
}

final rawSearchQueryProvider =
    NotifierProvider<RawSearchQueryNotifier, String>(RawSearchQueryNotifier.new);
final debouncedSearchQueryProvider =
    NotifierProvider<DebouncedSearchQueryNotifier, String>(DebouncedSearchQueryNotifier.new);

enum TaskListFilter { all, todo, inProgress, completed, notCompleted }

extension TaskListFilterX on TaskListFilter {
  String get label {
    switch (this) {
      case TaskListFilter.all:
        return 'All';
      case TaskListFilter.todo:
        return 'To-Do';
      case TaskListFilter.inProgress:
        return 'In Progress';
      case TaskListFilter.completed:
        return 'Completed';
      case TaskListFilter.notCompleted:
        return 'Not Completed';
    }
  }
}

final taskListFilterProvider =
    NotifierProvider<TaskListFilterNotifier, TaskListFilter>(TaskListFilterNotifier.new);

class TaskListFilterNotifier extends Notifier<TaskListFilter> {
  @override
  TaskListFilter build() => TaskListFilter.all;

  void set(TaskListFilter filter) => state = filter;
}

class RawSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void set(String value) => state = value;
}

class DebouncedSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void set(String value) => state = value;
}

final visibleTasksProvider = Provider<List<Task>>((ref) {
  final tasksAsync = ref.watch(allTasksProvider);
  final filter = ref.watch(taskListFilterProvider);
  final query = ref.watch(debouncedSearchQueryProvider).trim().toLowerCase();

  final tasks = tasksAsync.asData?.value ?? const <Task>[];
  final now = DateTime.now();

  return tasks.where((task) {
    final statusMatch = switch (filter) {
      TaskListFilter.all => true,
      TaskListFilter.todo => task.status == TaskStatus.todo,
      TaskListFilter.inProgress => task.status == TaskStatus.inProgress,
      TaskListFilter.completed => task.status == TaskStatus.done,
      TaskListFilter.notCompleted => task.status != TaskStatus.done && task.endDateTime.isBefore(now),
    };
    final searchMatch = query.isEmpty || task.title.toLowerCase().contains(query);
    return statusMatch && searchMatch;
  }).toList();
});

final taskDraftProvider = AsyncNotifierProvider<TaskDraftNotifier, TaskDraft?>(TaskDraftNotifier.new);

class TaskDraftNotifier extends AsyncNotifier<TaskDraft?> {
  TaskRepository get _repository => ref.read(taskRepositoryProvider);

  @override
  FutureOr<TaskDraft?> build() => _repository.getDraft();

  Future<void> saveDraft(TaskDraft draft) async {
    state = AsyncData(draft);
    await _repository.saveDraft(draft);
  }

  Future<void> clearDraft() async {
    state = const AsyncData(null);
    await _repository.clearDraft();
  }
}

bool isTaskBlocked(Task task, List<Task> tasks) {
  final blockedById = task.blockedByTaskId;
  if (blockedById == null) {
    return false;
  }

  final blocker = tasks.cast<Task?>().firstWhere(
        (candidate) => candidate?.id == blockedById,
        orElse: () => null,
      );

  if (blocker == null) {
    return false;
  }

  return blocker.status != TaskStatus.done;
}

bool isTimeWindowBlocked(Task task, List<Task> tasks) {
  for (final other in tasks) {
    if (other.id == task.id || other.status == TaskStatus.done) {
      continue;
    }

    final overlap =
        task.startDateTime.isBefore(other.endDateTime) && task.endDateTime.isAfter(other.startDateTime);
    if (!overlap) {
      continue;
    }

    final otherHasPriority = other.startDateTime.isBefore(task.startDateTime) ||
        (other.startDateTime.isAtSameMomentAs(task.startDateTime) && other.id.compareTo(task.id) < 0);
    if (otherHasPriority) {
      return true;
    }
  }
  return false;
}
