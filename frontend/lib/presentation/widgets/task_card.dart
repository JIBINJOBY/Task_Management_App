import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/models/task.dart';
import 'highlighted_text.dart';

class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.task,
    required this.blocked,
    required this.blockedByTime,
    required this.blockedByTitle,
    required this.searchQuery,
    required this.onTap,
    required this.onDelete,
    required this.onStatusChanged,
    required this.onMarkDone,
  });

  final Task task;
  final bool blocked;
  final bool blockedByTime;
  final String? blockedByTitle;
  final String searchQuery;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final ValueChanged<TaskStatus> onStatusChanged;
  final VoidCallback onMarkDone;

  Color _statusColor(BuildContext context) {
    switch (task.status) {
      case TaskStatus.todo:
        return Colors.orange.shade700;
      case TaskStatus.inProgress:
        return Theme.of(context).colorScheme.primary;
      case TaskStatus.done:
        return Colors.green.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(context);

    return Opacity(
      opacity: blocked ? 0.62 : 1,
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: HighlightedText(
                        text: task.title,
                        query: searchQuery,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 8),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'delete') {
                          onDelete();
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem<String>(value: 'delete', child: Text('Delete')),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  task.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _ChipLabel(
                      label: task.status.label,
                      textColor: statusColor,
                      background: statusColor.withValues(alpha: 0.1),
                      icon: Icons.flag_rounded,
                    ),
                    _ChipLabel(
                      label: DateFormat.yMMMd().add_jm().format(task.dueDate),
                      textColor: Colors.grey.shade800,
                      background: Colors.grey.shade200,
                      icon: Icons.calendar_today_rounded,
                    ),
                    if (blocked)
                      _ChipLabel(
                        label: blockedByTime
                            ? 'Blocked by Time Overlap'
                            : (blockedByTitle == null ? 'Blocked' : 'Blocked by $blockedByTitle'),
                        textColor: Colors.grey.shade800,
                        background: Colors.grey.shade300,
                        icon: Icons.lock_rounded,
                      ),
                  ],
                ),
                if (!blocked && task.status != TaskStatus.done) ...[
                  const SizedBox(height: 10),
                  FilledButton.tonalIcon(
                    onPressed: onMarkDone,
                    icon: const Icon(Icons.check_circle_rounded),
                    label: const Text('Mark as Done'),
                  ),
                ],
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    width: 180,
                    child: DropdownButtonFormField<TaskStatus>(
                      initialValue: task.status,
                      decoration: const InputDecoration(
                        labelText: 'Quick Status',
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      items: TaskStatus.values
                          .map((status) => DropdownMenuItem(value: status, child: Text(status.label)))
                          .toList(),
                      onChanged: blocked
                          ? null
                          : (status) {
                              if (status == null || status == task.status) {
                                return;
                              }
                              onStatusChanged(status);
                            },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChipLabel extends StatelessWidget {
  const _ChipLabel({
    required this.label,
    required this.textColor,
    required this.background,
    required this.icon,
  });

  final String label;
  final Color textColor;
  final Color background;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
