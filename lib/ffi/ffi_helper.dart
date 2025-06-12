import 'dart:ffi';
import 'package:ffi/ffi.dart';

import 'ffi_bindings.dart';
import '../widgets/task_model.dart';

/// ==================== CREATE ====================
Future<void> addTaskHelper({
  required String title,
  required String description,
  required int timestamp,
  required String kategori,
}) async {
  final titlePtr = title.toNativeUtf8();
  final descPtr = description.toNativeUtf8();
  final catPtr = kategori.toNativeUtf8();

  addTaskNative(titlePtr, descPtr, timestamp, catPtr);

  malloc.free(titlePtr);
  malloc.free(descPtr);
  malloc.free(catPtr);
}

/// ==================== READ ====================

Future<int> getTaskHelper(int id) async {
  return getTaskNative(id);
}

Future<List<Task>> getTaskByDateHelper(int date) async {
  final countPtr = calloc<Int32>();
  final taskPtr = getTaskByDateNative(date, countPtr);
  final count = countPtr.value;

  final tasks = <Task>[];

  for (int i = 0; i < count; i++) {
    final native = taskPtr.elementAt(i).ref;
    tasks.add(Task(
      id: native.id,
      title: native.title.toDartString(),
      description: native.description.toDartString(),
      timestamp: native.timestamp,
      isComplete: native.isComplete == 1,
      isDeleted: native.isDeleted == 1,
      category: native.category.toDartString(),
    ));
  }

  calloc.free(countPtr);
  return tasks;
}

Future<int> getDoneTaskCountHelper(int date) async {
  return getDoneTaskCountNative(date);
}

Future<int> getDoneTaskCountTodayHelper(int date) async {
  return getDoneTaskCountTodayNative(date);
}

Future<int> getTaskCountHelper(int date) async {
  return getTaskCountNative(date);
}

Future<int> getAllTasksHelper() async {
  return getAllTasksNative();
}

/// ==================== UPDATE ====================

Future<int> updateTaskHelper({
  required int id,
  required String newTitle,
  required String newDescription,
  required int newTimestamp,
}) async {
  final titlePtr = newTitle.toNativeUtf8();
  final descPtr = newDescription.toNativeUtf8();

  final result = updateTaskNative(id, titlePtr, descPtr, newTimestamp);

  malloc.free(titlePtr);
  malloc.free(descPtr);

  return result;
}

Future<int> changeStatusCompleteHelper(int id) async {
  return changeStatusCompleteNative(id);
}

Future<int> delayTaskHelper(int id) async {
  return delayTaskNative(id);
}

/// ==================== DELETE / RESTORE ====================

Future<int> deleteTaskHelper(int id) async {
  return deleteTaskNative(id);
}

Future<int> restoreTaskHelper(int id) async {
  return restoreTaskNative(id);
}
