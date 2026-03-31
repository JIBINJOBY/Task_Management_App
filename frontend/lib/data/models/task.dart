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
    required this.status,
    this.blockedByTaskId,
  });

  final String id;
  final String title;
  final String description;
  final DateTime dueDate;
  final TaskStatus status;
  final String? blockedByTaskId;

  Task copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dueDate,
    TaskStatus? status,
    String? blockedByTaskId,
    bool clearBlockedBy = false,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
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
      'status': status.name,
      'blockedByTaskId': blockedByTaskId,
    };
  }

  factory Task.fromJson(Map<dynamic, dynamic> json) {
    return Task(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      dueDate: DateTime.parse(json['dueDate'] as String),
      status: TaskStatusX.fromStorage(json['status'] as String),
      blockedByTaskId: json['blockedByTaskId'] as String?,
    );
  }
}

class TaskDraft {
  const TaskDraft({
    this.title = '',
    this.description = '',
    this.dueDate,
    this.status = TaskStatus.todo,
    this.blockedByTaskId,
  });

  final String title;
  final String description;
  final DateTime? dueDate;
  final TaskStatus status;
  final String? blockedByTaskId;

  TaskDraft copyWith({
    String? title,
    String? description,
    DateTime? dueDate,
    TaskStatus? status,
    String? blockedByTaskId,
    bool clearBlockedBy = false,
    bool clearDueDate = false,
  }) {
    return TaskDraft(
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: clearDueDate ? null : dueDate ?? this.dueDate,
      status: status ?? this.status,
      blockedByTaskId: clearBlockedBy ? null : blockedByTaskId ?? this.blockedByTaskId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'dueDate': dueDate?.toIso8601String(),
      'status': status.name,
      'blockedByTaskId': blockedByTaskId,
    };
  }

  factory TaskDraft.fromJson(Map<dynamic, dynamic> json) {
    final dueDateValue = json['dueDate'];
    return TaskDraft(
      title: (json['title'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      dueDate: dueDateValue == null ? null : DateTime.parse(dueDateValue as String),
      status: TaskStatusX.fromStorage((json['status'] as String?) ?? TaskStatus.todo.name),
      blockedByTaskId: json['blockedByTaskId'] as String?,
    );
  }
}
