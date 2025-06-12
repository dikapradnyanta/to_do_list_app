import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'task_struct.dart'; // Penting: berisi NativeTask struct

// Load native library
final DynamicLibrary nativeLib = Platform.isAndroid
    ? DynamicLibrary.open("libtask.so")
    : Platform.isMacOS
        ? DynamicLibrary.open("libtask.dylib")
        : DynamicLibrary.process();

/// ====================== CREATE ======================

// C: int addTask(const char* title, const char* description, int date, const char* category);
final int Function(Pointer<Utf8>, Pointer<Utf8>, int, Pointer<Utf8>)
    addTaskNative = nativeLib
        .lookup<NativeFunction<Int32 Function(Pointer<Utf8>, Pointer<Utf8>, Int32, Pointer<Utf8>)>>('addTask')
        .asFunction();

/// ====================== READ ======================

// C: int getTask(int id);
final int Function(int) getTaskNative = nativeLib
    .lookup<NativeFunction<Int32 Function(Int32)>>('getTask')
    .asFunction();

// C: Pointer<NativeTask> getTaskByDate(int date, int* count);
typedef GetTaskByDateC = Pointer<NativeTask> Function(Int32, Pointer<Int32>);
typedef GetTaskByDateDart = Pointer<NativeTask> Function(int, Pointer<Int32>);

final GetTaskByDateDart getTaskByDateNative = nativeLib
    .lookup<NativeFunction<GetTaskByDateC>>('getTaskByDate')
    .asFunction();

// C: int getDoneTaskCount(int date);
final int Function(int) getDoneTaskCountNative = nativeLib
    .lookup<NativeFunction<Int32 Function(Int32)>>('getDoneTaskCount')
    .asFunction();

// C: int getDoneTaskCountToday(int date);
final int Function(int) getDoneTaskCountTodayNative = nativeLib
    .lookup<NativeFunction<Int32 Function(Int32)>>('getDoneTaskCountToday')
    .asFunction();

// C: int getTaskCount(int date);
final int Function(int) getTaskCountNative = nativeLib
    .lookup<NativeFunction<Int32 Function(Int32)>>('getTaskCount')
    .asFunction();

// C: int getAllTasks();
final int Function() getAllTasksNative = nativeLib
    .lookup<NativeFunction<Int32 Function()>>('getAllTasks')
    .asFunction();

/// ====================== UPDATE ======================

// C: int updateTask(int id, const char* title, const char* desc, int date);
final int Function(int, Pointer<Utf8>, Pointer<Utf8>, int)
    updateTaskNative = nativeLib
        .lookup<NativeFunction<Int32 Function(Int32, Pointer<Utf8>, Pointer<Utf8>, Int32)>>('updateTask')
        .asFunction();

// C: int changeStatusComplete(int id);
final int Function(int) changeStatusCompleteNative = nativeLib
    .lookup<NativeFunction<Int32 Function(Int32)>>('changeStatusComplete')
    .asFunction();

// C: int delayTask(int id);
final int Function(int) delayTaskNative = nativeLib
    .lookup<NativeFunction<Int32 Function(Int32)>>('delayTask')
    .asFunction();

/// ====================== DELETE / RESTORE ======================

// C: int deleteTask(int id);
final int Function(int) deleteTaskNative = nativeLib
    .lookup<NativeFunction<Int32 Function(Int32)>>('deleteTask')
    .asFunction();

// C: int restoreTask(int id);
final int Function(int) restoreTaskNative = nativeLib
    .lookup<NativeFunction<Int32 Function(Int32)>>('restoreTask')
    .asFunction();
