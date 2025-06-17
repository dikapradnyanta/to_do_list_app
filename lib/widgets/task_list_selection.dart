// file: widgets/task_list_selection.dart

import 'package:flutter/material.dart';
import '../ffi/ffi_helper.dart';
import 'task_tile.dart';
import 'task_model.dart';

class TaskListWithSelection extends StatefulWidget {
  final List<Task> tasks;
  final VoidCallback? onUpdated;
  final ValueChanged<bool>? onSelectingChanged;
  final DateTime selectedDay;
  final ScrollController weekScrollController;

  const TaskListWithSelection({
    super.key,
    required this.tasks,
    required this.selectedDay,
    required this.weekScrollController,
    this.onUpdated,
    this.onSelectingChanged,
  });

  @override
  State<TaskListWithSelection> createState() => _TaskListWithSelectionState();
}

class _TaskListWithSelectionState extends State<TaskListWithSelection> {
  bool _isSelecting = false;
  final Set<int> _selectedTaskIds = {};
  List<Task> _localTasks = []; // Local copy for optimistic updates

  @override
  void initState() {
    super.initState();
    _localTasks = List.from(widget.tasks);
  }

  @override
  void didUpdateWidget(covariant TaskListWithSelection oldWidget) {
    super.didUpdateWidget(oldWidget);
    print('didUpdateWidget called - updating local tasks');

    // Always update local tasks when parent provides new data
    final oldCount = _localTasks.length;
    _localTasks = List.from(widget.tasks);

    print('Local tasks updated: $oldCount -> ${_localTasks.length}');

    // Force setState to ensure UI rebuild
    if (mounted) {
      setState(() {
        // Force rebuild
      });
    }

    _selectedTaskIds.clear();
    if (_isSelecting) {
      setState(() => _isSelecting = false);
      widget.onSelectingChanged?.call(false);
    }
  }

  void _toggleSelectMode(bool value) {
    setState(() => _isSelecting = value);
    if (!value) _selectedTaskIds.clear();
    widget.onSelectingChanged?.call(value);
  }

  void _onSelected(bool selected, int id) {
    setState(() {
      if (selected) {
        _selectedTaskIds.add(id);
        if (!_isSelecting) {
          _isSelecting = true;
          widget.onSelectingChanged?.call(true);
        }
      } else {
        _selectedTaskIds.remove(id);
        if (_selectedTaskIds.isEmpty) {
          _isSelecting = false;
          widget.onSelectingChanged?.call(false);
        }
      }
    });
  }

  Future<void> _deleteSelected() async {
    // Optimistic update: Remove tasks from UI immediately
    final tasksToDelete = _selectedTaskIds.toList();
    setState(() {
      _localTasks.removeWhere((task) => tasksToDelete.contains(task.id));
    });

    _toggleSelectMode(false);

    // Then call native functions
    try {
      for (var id in tasksToDelete) {
        await deleteTaskHelper(id);
      }
    } catch (e) {
      // If error, reload from server to restore correct state
      print('Error deleting tasks: $e');
    } finally {
      // Always reload to ensure consistency
      widget.onUpdated?.call();
    }
  }

  Future<void> _delaySelected() async {
    _toggleSelectMode(false);

    try {
      for (var id in _selectedTaskIds) {
        await delayTaskHelper(id);
      }
    } catch (e) {
      print('Error delaying tasks: $e');
    } finally {
      widget.onUpdated?.call();
    }
  }

  Future<void> _toggleTaskComplete(Task task) async {
    print('TaskListWithSelection: Received toggle request for task ${task.id}');

    // Update local tasks immediately with the new task data from TaskTile
    setState(() {
      final index = _localTasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        _localTasks[index] = task;
        print(
          'Local task updated from TaskTile: ${task.title} -> ${task.isComplete}',
        );
      }
    });

    // Reload parent data to ensure consistency
    widget.onUpdated?.call();
  }

  Future<void> _deleteTask(Task task) async {
    // Optimistic update: Remove from UI immediately
    setState(() {
      _localTasks.removeWhere((t) => t.id == task.id);
    });

    try {
      await deleteTaskHelper(task.id);
    } catch (e) {
      print('Error deleting task: $e');
    } finally {
      widget.onUpdated?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_isSelecting)
          Container(
            color: Colors.grey[100],
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text('${_selectedTaskIds.length} selected'),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: _deleteSelected,
                ),
                IconButton(
                  icon: const Icon(Icons.schedule, color: Colors.blue),
                  onPressed: _delaySelected,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => _toggleSelectMode(false),
                ),
              ],
            ),
          ),
        Expanded(
          child: ListView.builder(
            itemCount: _localTasks.length,
            itemBuilder: (_, index) {
              final task = _localTasks[index];
              final isSelected = _selectedTaskIds.contains(task.id);

              return TaskTile(
                task: task,
                isSelecting: _isSelecting,
                isSelected: isSelected,
                onSelected: (val) => _onSelected(val, task.id),
                onToggleComplete: _toggleTaskComplete,
                onDelete: () => _deleteTask(task),
              );
            },
          ),
        ),
      ],
    );
  }
}
