import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/task.dart';
import '../providers/task_providers.dart';
import '../widgets/task_card.dart';
import 'task_form_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  Timer? _debounce;
  Timer? _autoProgressTimer;

  @override
  void dispose() {
    _debounce?.cancel();
    _autoProgressTimer?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _autoProgressTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      ref.read(allTasksProvider.notifier).promoteDueTodoTasks();
    });
  }

  void _onSearchChanged(String value) {
    ref.read(rawSearchQueryProvider.notifier).set(value);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      ref.read(debouncedSearchQueryProvider.notifier).set(value);
    });
  }

  Future<void> _openForm({Task? task}) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => TaskFormScreen(editingTask: task)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(allTasksProvider);
    final visibleTasks = ref.watch(visibleTasksProvider);
    final allTasks = tasksAsync.asData?.value ?? const <Task>[];
    final searchQuery = ref.watch(rawSearchQueryProvider);
    final selectedFilter = ref.watch(filterStatusProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Management'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => ref.read(allTasksProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Task'),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: _onSearchChanged,
                    decoration: const InputDecoration(
                      hintText: 'Search by title',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 150,
                  child: DropdownButtonFormField<TaskStatus?>(
                    initialValue: selectedFilter,
                    decoration: const InputDecoration(labelText: 'Filter'),
                    items: [
                      const DropdownMenuItem<TaskStatus?>(value: null, child: Text('All')),
                      ...TaskStatus.values.map(
                        (status) => DropdownMenuItem<TaskStatus?>(value: status, child: Text(status.label)),
                      ),
                    ],
                    onChanged: (value) => ref.read(filterStatusProvider.notifier).set(value),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Expanded(
              child: tasksAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(child: Text('Failed to load tasks: $error')),
                data: (_) {
                  if (visibleTasks.isEmpty) {
                    return const Center(child: Text('No tasks found. Tap + to create one.'));
                  }

                  return ListView.separated(
                    itemCount: visibleTasks.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final task = visibleTasks[index];
                      final blocked = isTaskBlocked(task, allTasks);
                      final blocker = task.blockedByTaskId == null
                          ? null
                          : allTasks.cast<Task?>().firstWhere(
                                (candidate) => candidate?.id == task.blockedByTaskId,
                                orElse: () => null,
                              );

                      return AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        child: TaskCard(
                          key: ValueKey(task.id),
                          task: task,
                          blocked: blocked,
                          blockedByTitle: blocker?.title,
                          searchQuery: searchQuery,
                          onTap: () => _openForm(task: task),
                          onDelete: () => ref.read(allTasksProvider.notifier).deleteTask(task.id),
                          onStatusChanged: (status) {
                            ref.read(allTasksProvider.notifier).updateTask(
                                  task.copyWith(status: status),
                                );
                          },
                          onMarkDone: () {
                            ref.read(allTasksProvider.notifier).updateTask(
                                  task.copyWith(status: TaskStatus.done),
                                );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
