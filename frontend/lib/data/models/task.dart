enum TaskStatus { todo, inProgress, done }

extension TaskStatusX on TaskStatus {
  String get label {
    switch (this) {
      case TaskStatus.todo:
        return 'To-Do';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.done:
        return 'Done';
    }
  }

  static TaskStatus fromStorage(String value) {
    return TaskStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => TaskStatus.todo,
    );
  }
}

class Task {
  const Task({
    required this.id,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.startDateTime,
    required this.endDateTime,
    required this.status,
    this.blockedByTaskId,
  });

  final String id;
  final String title;
  final String description;
  final DateTime dueDate;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final TaskStatus status;
  final String? blockedByTaskId;

  Task copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dueDate,
    DateTime? startDateTime,
    DateTime? endDateTime,
    TaskStatus? status,
    String? blockedByTaskId,
    bool clearBlockedBy = false,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      startDateTime: startDateTime ?? this.startDateTime,
      endDateTime: endDateTime ?? this.endDateTime,
      status: status ?? this.status,
      blockedByTaskId: clearBlockedBy ? null : blockedByTaskId ?? this.blockedByTaskId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dueDate': dueDate.toIso8601String(),
      'startDateTime': startDateTime.toIso8601String(),
      'endDateTime': endDateTime.toIso8601String(),
      'status': status.name,
      'blockedByTaskId': blockedByTaskId,
    };
  }

  factory Task.fromJson(Map<dynamic, dynamic> json) {
    final dueDate = DateTime.parse(json['dueDate'] as String);
    final startRaw = json['startDateTime'] as String?;
    final endRaw = json['endDateTime'] as String?;
    final endDateTime = endRaw == null ? dueDate : DateTime.parse(endRaw);
    final startDateTime = startRaw == null ? endDateTime.subtract(const Duration(hours: 1)) : DateTime.parse(startRaw);

    return Task(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      dueDate: dueDate,
      startDateTime: startDateTime,
      endDateTime: endDateTime,
      status: TaskStatusX.fromStorage(json['status'] as String),
      blockedByTaskId: json['blockedByTaskId'] as String?,
    );
  }
}

class TaskDraft {
  const TaskDraft({
    this.title = '',
    this.description = '',
    this.startDateTime,
    this.endDateTime,
    this.status = TaskStatus.todo,
    this.blockedByTaskId,
  });

  final String title;
  final String description;
  final DateTime? startDateTime;
  final DateTime? endDateTime;
  final TaskStatus status;
  final String? blockedByTaskId;

  TaskDraft copyWith({
    String? title,
    String? description,
    DateTime? startDateTime,
    DateTime? endDateTime,
    TaskStatus? status,
    String? blockedByTaskId,
    bool clearBlockedBy = false,
    bool clearStartDateTime = false,
    bool clearEndDateTime = false,
  }) {
    return TaskDraft(
      title: title ?? this.title,
      description: description ?? this.description,
      startDateTime: clearStartDateTime ? null : startDateTime ?? this.startDateTime,
      endDateTime: clearEndDateTime ? null : endDateTime ?? this.endDateTime,
      status: status ?? this.status,
      blockedByTaskId: clearBlockedBy ? null : blockedByTaskId ?? this.blockedByTaskId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'startDateTime': startDateTime?.toIso8601String(),
      'endDateTime': endDateTime?.toIso8601String(),
      'status': status.name,
      'blockedByTaskId': blockedByTaskId,
    };
  }

  factory TaskDraft.fromJson(Map<dynamic, dynamic> json) {
    final startValue = json['startDateTime'];
    final endValue = json['endDateTime'];
    return TaskDraft(
      title: (json['title'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      startDateTime: startValue == null ? null : DateTime.parse(startValue as String),
      endDateTime: endValue == null ? null : DateTime.parse(endValue as String),
      status: TaskStatusX.fromStorage((json['status'] as String?) ?? TaskStatus.todo.name),
      blockedByTaskId: json['blockedByTaskId'] as String?,
    );
  }
}
