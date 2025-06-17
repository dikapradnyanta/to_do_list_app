import 'package:flutter/material.dart';
import '../ffi/ffi_helper.dart';
import '../widgets/task_model.dart';

class RestoreTaskPage extends StatefulWidget {
  const RestoreTaskPage({super.key});

  @override
  State<RestoreTaskPage> createState() => _RestoreTaskPageState();
}

class _RestoreTaskPageState extends State<RestoreTaskPage> {
  List<Task> _deletedTasks = [];

  @override
  void initState() {
    super.initState();
    _loadDeletedTasks();
  }

  // Load all deleted tasks using native FFI helper
  Future<void> _loadDeletedTasks() async {
    final tasks = await getAllDeletedTasksHelper();
    setState(() {
      _deletedTasks = tasks;
    });
  }

  // Restore a single task
  Future<void> _restoreTask(Task task) async {
    final result = await restoreTaskHelper(task.id);
    if (result == 1) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Task "${task.title}" restored')));
      _loadDeletedTasks(); // reload the list
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to restore task')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Restore Deleted Tasks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDeletedTasks,
          ),
        ],
      ),
      body: _deletedTasks.isEmpty
          ? const Center(child: Text('No deleted tasks found.'))
          : ListView.builder(
              itemCount: _deletedTasks.length,
              itemBuilder: (context, index) {
                final task = _deletedTasks[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ListTile(
                    title: Text(task.title),
                    subtitle: Text(task.description),
                    trailing: IconButton(
                      icon: const Icon(Icons.restore),
                      onPressed: () => _restoreTask(task),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
