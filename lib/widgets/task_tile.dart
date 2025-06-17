import 'package:flutter/material.dart';
import 'package:to_do_list_app/alert.dart';
import 'package:to_do_list_app/ffi/ffi_helper.dart';
import 'task_model.dart';
import '../edit_task.dart';

class TaskTile extends StatefulWidget {
  final Task task;
  final bool isSelecting;
  final bool isSelected;
  final ValueChanged<bool>? onSelected;
  final ValueChanged<Task>? onToggleComplete;
  final VoidCallback? onDelete;

  const TaskTile({
    super.key,
    required this.task,
    this.isSelecting = false,
    this.isSelected = false,
    this.onSelected,
    this.onToggleComplete,
    this.onDelete,
  });

  @override
  State<TaskTile> createState() => _TaskTileState();
}

class _TaskTileState extends State<TaskTile> {
  bool _isUpdating = false;

  Future<void> _toggleTaskComplete() async {
    if (_isUpdating) return;

    setState(() => _isUpdating = true);

    try {
      final result = await changeStatusCompleteHelper(widget.task.id);
      if (result == 1) {
        // PERBAIKAN: Langsung gunakan widget.task.isComplete yang sudah diupdate dari parent
        // Tidak perlu state management lokal yang bisa menyebabkan inkonsistensi
        final newCompleteStatus = !widget.task.isComplete;

        final updatedTask = Task(
          id: widget.task.id,
          title: widget.task.title,
          description: widget.task.description,
          timestamp: widget.task.timestamp,
          isComplete: newCompleteStatus,
          isDeleted: widget.task.isDeleted,
          category: widget.task.category,
        );

        // Kirim Task baru ke parent
        widget.onToggleComplete?.call(updatedTask);

        // Tampilkan toast
        showCustomToast(
          context,
          newCompleteStatus
              ? 'Task marked as complete!'
              : 'Task marked as incomplete!',
        );
      } else {
        showCustomToast(context, 'Failed to change task status');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<void> _deleteTask() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => CustomAlertDialog(
        title: 'Delete Task',
        message: 'Are you sure you want to delete "${widget.task.title}"?',
        onConfirm: () => Navigator.of(context).pop(true),
        onCancel: () => Navigator.of(context).pop(false),
        confirmText: 'Delete',
        cancelText: 'Cancel',
      ),
    );

    if (confirmed != true) return;

    setState(() => _isUpdating = true);
    try {
      final result = await deleteTaskHelper(widget.task.id);
      if (result == 1) {
        widget.onDelete?.call();
        showCustomToast(context, "Task deleted successfully!");
      } else {
        showCustomToast(context, "Failed to delete task");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  void _goToEditTask() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditTaskPage(task: widget.task)),
    );
  }

  Future<void> _delayTask() async {
    setState(() => _isUpdating = true);
    try {
      final result = await delayTaskHelper(widget.task.id);
      if (result == 1) {
        showCustomToast(context, "Task delayed successfully!");
      } else {
        showCustomToast(context, "Failed to delay task");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  String _formatTime(int timestamp) {
    try {
      return DateTime.fromMillisecondsSinceEpoch(
        timestamp * 1000,
      ).toLocal().toString().substring(11, 16);
    } catch (_) {
      return 'Invalid time';
    }
  }

  String _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'work':
        return '🔵';
      case 'personal':
        return '🟢';
      case 'health':
        return '🔴';
      case 'study':
        return '🟡';
      default:
        return '⚪';
    }
  }

  @override
  Widget build(BuildContext context) {
    // PERBAIKAN: Debug print yang lebih bersih
    debugPrint(
      'TaskTile render: ${widget.task.title} (${widget.task.isComplete ? "✓" : "○"})',
    );

    return Dismissible(
      key: ValueKey(widget.task.id),
      direction: DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        if (_isUpdating) return false;

        if (direction == DismissDirection.endToStart) {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Delete Task'),
              content: Text(
                'Are you sure you want to delete "${widget.task.title}"?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text("Delete"),
                ),
              ],
            ),
          );
          if (confirm == true) await _deleteTask();
          return false;
        }

        if (direction == DismissDirection.startToEnd) {
          await _delayTask();
          return false;
        }

        return false;
      },
      background: Container(
        color: Colors.blue,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Row(
          children: [
            Icon(Icons.arrow_forward, color: Colors.white),
            SizedBox(width: 8),
            Text("Delay Task", style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
      secondaryBackground: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: GestureDetector(
        onLongPress: () {
          if (!widget.isSelecting) {
            widget.onSelected?.call(true);
          }
        },
        onTap: widget.isSelecting
            ? () {
                widget.onSelected?.call(!widget.isSelected);
                showCustomToast(
                  context,
                  widget.isSelected
                      ? "Deselected"
                      : "Selected: ${widget.task.title}",
                );
              }
            : null,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: widget.isSelected ? Colors.blue[50] : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.task.isComplete
                  ? Colors.green
                  : Colors
                        .grey[300]!, // PERBAIKAN: Gunakan widget.task.isComplete langsung
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // PERBAIKAN: Checkbox yang lebih sederhana
              widget.isSelecting
                  ? Checkbox(
                      value: widget.isSelected,
                      onChanged: (val) {
                        widget.onSelected?.call(val ?? false);
                        showCustomToast(
                          context,
                          (val ?? false)
                              ? "Selected: ${widget.task.title}"
                              : "Deselected",
                        );
                      },
                    )
                  : _isUpdating
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : GestureDetector(
                      onTap: _toggleTaskComplete,
                      child: Checkbox(
                        value: widget
                            .task
                            .isComplete, // PERBAIKAN: Langsung dari widget.task
                        onChanged: (_) => _toggleTaskComplete(),
                        shape: const CircleBorder(),
                        activeColor: Colors.green,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: widget.isSelecting ? null : _goToEditTask,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.task.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          decoration:
                              widget
                                  .task
                                  .isComplete // PERBAIKAN: Langsung dari widget.task
                              ? TextDecoration.lineThrough
                              : null,
                          color:
                              widget
                                  .task
                                  .isComplete // PERBAIKAN: Langsung dari widget.task
                              ? Colors.grey
                              : Colors.black,
                        ),
                      ),
                      if (widget.task.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          widget.task.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color:
                                widget
                                    .task
                                    .isComplete // PERBAIKAN: Langsung dari widget.task
                                ? Colors.grey
                                : Colors.grey[700],
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            '${_getCategoryColor(widget.task.category)} ${widget.task.category}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            _formatTime(widget.task.timestamp),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (!widget.isSelecting)
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: _goToEditTask,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
