import 'package:ffi/ffi.dart';
import '../ffi/task_struct.dart';

class Task {
  final int id;
  final String title;
  final String description;
  final int timestamp;
  final bool isComplete;
  final bool isDeleted;
  final String category;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.timestamp,
    required this.isComplete,
    required this.isDeleted,
    required this.category,
  });

  factory Task.fromNative(NativeTask native) {
    return Task(
      id: native.id,
      title: native.title.address != 0 ? native.title.toDartString() : '',
      description: native.description.address != 0
          ? native.description.toDartString()
          : '',
      timestamp: native.timestamp,
      isComplete: native.isComplete == 1,
      isDeleted: native.isDeleted == 1,
      category: native.category.address != 0
          ? native.category.toDartString()
          : '',
    );
  }
}
