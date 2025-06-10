import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:to_do_list_app/ffi/ffi_bindings.dart';
import 'ffi_binding.dart'; // pastikan fungsi-fungsi dari nativeLib di sini

// CREATE
Future<int> addTaskHelper({
  required int id,
  required String title,
  required String description,
  required int timestamp,
}) async {
  final titlePtr = title.toNativeUtf8();
  final descPtr = description.toNativeUtf8();

  final result = addTaskNative(id, titlePtr, descPtr, timestamp); // dari binding

  calloc.free(titlePtr);
  calloc.free(descPtr);

  return result;
}

// READ
Future<int> getTaskHelper(int id) async {
  return getTaskNative(id); // dari binding
}

Future<int> getTaskByDateHelper(int date) async {
  return getTaskByDateNative(date);
}

Future<int> getDoneTaskCountHelper(int date) async {
  return getDoneTaskCountNative(date);
}

Future<int> getAllTasksHelper() async {
  return getAllTasksNative();
}

Future<int> getTaskCountHelper(int date) async {
  return getTaskCountNative(date);
}

Future<int> getDoneTaskCountTodayHelper(int date) async {
  return getDoneTaskCountTodayNative(date);
}

// UPDATE
Future<int> updateTaskHelper({
  required int id,
  required String newTitle,
  required String newDescription,
  required int newTimestamp,
  required bool isDone,
}) async {
  final titlePtr = newTitle.toNativeUtf8();
  final descPtr = newDescription.toNativeUtf8();

  final result = updateTaskNative(
    id,
    titlePtr,
    descPtr,
    newTimestamp,
    isDone ? 1 : 0,
  );

  calloc.free(titlePtr);
  calloc.free(descPtr);

  return result;
}

Future<int> changeStatusCompleteHelper(int id) async {
  return changeStatusCompleteNative(id);
}

Future<int> delayTaskHelper(int id) async {
  return delayTaskNative(id);
}

// DELETE / RESTORE
Future<int> deleteTaskHelper(int id) async {
  return deleteTaskNative(id);
}

Future<int> restoreTaskHelper(int id) async {
  return restoreTaskNative(id);
}
