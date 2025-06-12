import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';

/// Load native C++ library
final DynamicLibrary nativeLib = Platform.isAndroid
    ? DynamicLibrary.open("libtask.so") // Android
    : DynamicLibrary.process(); // macOS, Windows (ubah jika perlu)

// Fungsi-fungsi C++ yang di-export melalui extern "C"
//=============== CREATE SECTION ===================
// CREATE
//addTask(id, title, description, date)
final int Function(Pointer<Utf8>, Pointer<Utf8>, int) addTaskNative = nativeLib
    .lookup<
      NativeFunction<Int32 Function(Pointer<Utf8>, Pointer<Utf8>, Int32)>
    >('addTask')
    .asFunction();

//=============== READ SECTION ===================

// getTask(id)
final int Function(int) getTaskNative = nativeLib
    .lookup<NativeFunction<Int32 Function(Int32)>>('getTask')
    .asFunction();

///getTaskByDate(date)
final int Function(int) getTaskByDateNative = nativeLib
    .lookup<NativeFunction<Int32 Function(Int32)>>('getTaskByDate')
    .asFunction();

///getDoneTaskCount(date)
final int Function(int) getDoneTaskCountNative = nativeLib
    .lookup<NativeFunction<Int32 Function(Int32)>>('getDoneTaskCount')
    .asFunction();

///getTaskCount(date)
final int Function() getAllTasksNative = nativeLib
    .lookup<NativeFunction<Int32 Function()>>('getAllTasks')
    .asFunction();

///getAllTasks()

final int Function(int) getTaskCountByDateNative = nativeLib
    .lookup<NativeFunction<Int32 Function(Int32)>>('getTaskCountByDate')
    .asFunction();

///============= UPDATE ====================

///UpdateTask(id, title, description, date)
final int Function(Pointer<Utf8>, Pointer<Utf8>, int) updateTaskNative =
    nativeLib
        .lookup<
          NativeFunction<Int32 Function(Pointer<Utf8>, Pointer<Utf8>, Int32)>
        >('updateTask')
        .asFunction();

///changeStatusComplete(id)
final int Function(int) changeStatusCompleteNative = nativeLib
    .lookup<NativeFunction<Int32 Function(Int32)>>('changeStatusComplete')
    .asFunction();

///delayTask(id)
final int Function(int) delayTaskNative = nativeLib
    .lookup<NativeFunction<Int32 Function(Int32)>>('delayTask')
    .asFunction();

/// ================== DELETE ==================

/// deleteTask(id)
final int Function(int) deleteTaskNative = nativeLib
    .lookup<NativeFunction<Int32 Function(Int32)>>('deleteTask')
    .asFunction();

/// restoreTask(id)
final int Function(int) restoreTaskNative = nativeLib
    .lookup<NativeFunction<Int32 Function(Int32)>>('restoreTask')
    .asFunction();
