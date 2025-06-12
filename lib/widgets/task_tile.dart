// lib/widgets/task_tile.dart
import 'package:flutter/material.dart';
import 'task_model.dart';

class TaskTile extends StatelessWidget {
  final Task task;

  const TaskTile({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(task.title),
      subtitle: Text(task.description),
      trailing: Text(
        DateTime.fromMillisecondsSinceEpoch(
          task.timestamp * 1000,
        ).toLocal().toString().substring(11, 16),
      ),
    );
  }
}
