import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/models/task.dart';
import '../providers/task_providers.dart';

class TaskFormScreen extends ConsumerStatefulWidget {
  const TaskFormScreen({super.key, this.editingTask});

  final Task? editingTask;

  bool get isEditing => editingTask != null;

  @override
  ConsumerState<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends ConsumerState<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  DateTime? _startDateTime;
  DateTime? _endDateTime;
  TaskStatus _status = TaskStatus.todo;
  String? _blockedByTaskId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      final task = widget.editingTask!;
      _titleController.text = task.title;
      _descriptionController.text = task.description;
      _startDateTime = task.startDateTime;
      _endDateTime = task.endDateTime;
      _status = task.status;
      _blockedByTaskId = task.blockedByTaskId;
    } else {
      final draft = ref.read(taskDraftProvider).asData?.value;
      if (draft != null) {
        _titleController.text = draft.title;
        _descriptionController.text = draft.description;
        _startDateTime = draft.startDateTime;
        _endDateTime = draft.endDateTime;
        _status = draft.status;
        _blockedByTaskId = draft.blockedByTaskId;
      }

      _titleController.addListener(_persistDraft);
      _descriptionController.addListener(_persistDraft);
    }
  }

  @override
  void dispose() {
    _titleController.removeListener(_persistDraft);
    _descriptionController.removeListener(_persistDraft);
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _persistDraft() {
    if (widget.isEditing) {
      return;
    }

    final draft = TaskDraft(
      title: _titleController.text,
      description: _descriptionController.text,
      startDateTime: _startDateTime,
      endDateTime: _endDateTime,
      status: _status,
      blockedByTaskId: _blockedByTaskId,
    );

    ref.read(taskDraftProvider.notifier).saveDraft(draft);
  }

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final current = _startDateTime ?? now;
    final selected = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 20),
      initialDate: current,
    );

    if (selected != null) {
      final existing = _startDateTime ?? DateTime.now();
      setState(() {
        _startDateTime = DateTime(
          selected.year,
          selected.month,
          selected.day,
          existing.hour,
          existing.minute,
        );
      });
      _normalizeEndAfterStart();
      _persistDraft();
    }
  }

  Future<void> _pickStartTime() async {
    final initial = _startDateTime ?? DateTime.now();
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initial.hour, minute: initial.minute),
    );

    if (selected != null) {
      final base = _startDateTime ?? DateTime.now();
      setState(() {
        _startDateTime = DateTime(
          base.year,
          base.month,
          base.day,
          selected.hour,
          selected.minute,
        );
      });
      _normalizeEndAfterStart();
      _persistDraft();
    }
  }

  Future<void> _pickEndDate() async {
    final now = DateTime.now();
    final current = _endDateTime ?? _startDateTime ?? now;
    final selected = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 20),
      initialDate: current,
    );

    if (selected != null) {
      final existing = _endDateTime ?? (_startDateTime ?? now).add(const Duration(hours: 1));
      setState(() {
        _endDateTime = DateTime(
          selected.year,
          selected.month,
          selected.day,
          existing.hour,
          existing.minute,
        );
      });
      _normalizeEndAfterStart();
      _persistDraft();
    }
  }

  Future<void> _pickEndTime() async {
    final initial = _endDateTime ?? (_startDateTime ?? DateTime.now()).add(const Duration(hours: 1));
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initial.hour, minute: initial.minute),
    );

    if (selected != null) {
      final base = _endDateTime ?? (_startDateTime ?? DateTime.now());
      setState(() {
        _endDateTime = DateTime(
          base.year,
          base.month,
          base.day,
          selected.hour,
          selected.minute,
        );
      });
      _normalizeEndAfterStart();
      _persistDraft();
    }
  }

  void _normalizeEndAfterStart() {
    if (_startDateTime == null) {
      return;
    }
    if (_endDateTime == null || !_endDateTime!.isAfter(_startDateTime!)) {
      _endDateTime = _startDateTime!.add(const Duration(hours: 1));
    }
  }

  Future<void> _save() async {
    if (_isSaving || !_formKey.currentState!.validate() || _startDateTime == null || _endDateTime == null) {
      return;
    }
    if (!_endDateTime!.isAfter(_startDateTime!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    final notifier = ref.read(allTasksProvider.notifier);

    try {
      if (widget.isEditing) {
        final original = widget.editingTask!;
        await notifier.updateTask(
          original.copyWith(
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            dueDate: _endDateTime,
            startDateTime: _startDateTime,
            endDateTime: _endDateTime,
            status: _status,
            blockedByTaskId: _blockedByTaskId,
            clearBlockedBy: _blockedByTaskId == null,
          ),
        );
      } else {
        await notifier.createTask(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          startDateTime: _startDateTime!,
          endDateTime: _endDateTime!,
          status: _status,
          blockedByTaskId: _blockedByTaskId,
        );
        await ref.read(taskDraftProvider.notifier).clearDraft();
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(allTasksProvider).asData?.value ?? const <Task>[];
    final dependencyCandidates = tasks.where((task) => task.id != widget.editingTask?.id).toList();

    return Scaffold(
      appBar: AppBar(title: Text(widget.isEditing ? 'Edit Task' : 'Create Task')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Title'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Title is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Description'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Description is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: _pickStartDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Start Date',
                  suffixIcon: Icon(Icons.calendar_today_rounded),
                ),
                child: Text(
                  _startDateTime == null ? 'Select date' : DateFormat.yMMMMd().format(_startDateTime!),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ),
            if (_startDateTime == null)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 12),
                child: Text(
                  'Start date is required',
                  style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
                ),
              ),
            const SizedBox(height: 14),
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: _pickStartTime,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Start Time',
                  suffixIcon: Icon(Icons.schedule_rounded),
                ),
                child: Text(
                  _startDateTime == null
                      ? 'Select time'
                      : TimeOfDay(hour: _startDateTime!.hour, minute: _startDateTime!.minute)
                          .format(context),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ),
            const SizedBox(height: 14),
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: _pickEndDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'End Date',
                  suffixIcon: Icon(Icons.event_rounded),
                ),
                child: Text(
                  _endDateTime == null ? 'Select date' : DateFormat.yMMMMd().format(_endDateTime!),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ),
            const SizedBox(height: 14),
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: _pickEndTime,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'End Time',
                  suffixIcon: Icon(Icons.more_time_rounded),
                ),
                child: Text(
                  _endDateTime == null
                      ? 'Select time'
                      : TimeOfDay(hour: _endDateTime!.hour, minute: _endDateTime!.minute)
                          .format(context),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<TaskStatus>(
              initialValue: _status,
              decoration: const InputDecoration(labelText: 'Status'),
              items: TaskStatus.values
                  .map((status) => DropdownMenuItem(value: status, child: Text(status.label)))
                  .toList(),
              onChanged: (status) {
                if (status == null) {
                  return;
                }
                setState(() => _status = status);
                _persistDraft();
              },
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String?>(
              initialValue: _blockedByTaskId,
              decoration: const InputDecoration(labelText: 'Blocked By (Optional)'),
              items: [
                const DropdownMenuItem<String?>(value: null, child: Text('None')),
                ...dependencyCandidates.map(
                  (task) => DropdownMenuItem<String?>(
                    value: task.id,
                    child: Text(task.title, overflow: TextOverflow.ellipsis),
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() => _blockedByTaskId = value);
                _persistDraft();
              },
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_rounded),
              label: Text(_isSaving ? 'Saving...' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }
}
