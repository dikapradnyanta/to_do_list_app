import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'task_struct.dart'; // Penting: berisi NativeTask struct

// Load native library
final DynamicLibrary nativeLib = Platform.isAndroid
    ? DynamicLibrary.open("libtask.so")
    : DynamicLibrary.process();

/// ====================== DATABASE  ======================

typedef NativeSetLogPathC = Void Function(Pointer<Utf8>);
typedef NativeSetLogPathDart = void Function(Pointer<Utf8>);

final NativeSetLogPathDart nativeSetLogPath = nativeLib
    .lookup<NativeFunction<NativeSetLogPathC>>('setLogFilePath')
    .asFunction();

final initDBWithPathNative = nativeLib
    .lookupFunction<Void Function(Pointer<Utf8>), void Function(Pointer<Utf8>)>(
      'initDBWithPath',
    );

// C: void initDB();
typedef InitDBC = Void Function();
typedef InitDBDart = void Function();

final InitDBDart initDBNative = nativeLib
    .lookup<NativeFunction<InitDBC>>('initDB')
    .asFunction();

// C: int isDatabaseValid();
final int Function() isDatabaseValidNative = nativeLib
    .lookup<NativeFunction<Int32 Function()>>('isDatabaseValid')
    .asFunction();

// C: void setupDatabase();
typedef SetupDatabaseC = Void Function();
typedef SetupDatabaseDart = void Function();

final SetupDatabaseDart setupDatabaseNative = nativeLib
    .lookup<NativeFunction<SetupDatabaseC>>('setupDatabase')
    .asFunction();

// C: void loadDB();
typedef LoadDBC = Void Function();
typedef LoadDBDart = void Function();

final LoadDBDart loadDBNative = nativeLib
    .lookup<NativeFunction<LoadDBC>>('loadDB')
    .asFunction();

// C: void updateDB();
typedef UpdateDBC = Void Function();
typedef UpdateDBDart = void Function();

final UpdateDBDart updateDBNative = nativeLib
    .lookup<NativeFunction<UpdateDBC>>('updateDB')
    .asFunction();

/// ====================== CREATE ======================

// C: int addTask(const char* title, const char* description, int date, const char* category);
final int Function(Pointer<Utf8>, Pointer<Utf8>, int, Pointer<Utf8>)
addTaskNative = nativeLib
    .lookup<
      NativeFunction<
        Int32 Function(Pointer<Utf8>, Pointer<Utf8>, Int32, Pointer<Utf8>)
      >
    >('addTask')
    .asFunction();

/// ====================== READ ======================

// C: int getTask(int id);
final int Function(int) getTaskNative = nativeLib
    .lookup<NativeFunction<Int32 Function(Int32)>>('getTask')
    .asFunction();
//C : NativeTask* getAllDeletedtask(int* count)
typedef GetAllDeletedTasksC = Pointer<NativeTask> Function(Pointer<Int32>);
typedef GetAllDeletedTasksDart = Pointer<NativeTask> Function(Pointer<Int32>);
final GetAllDeletedTasksDart getAllDeletedTasksNative = nativeLib
    .lookup<NativeFunction<GetAllDeletedTasksC>>('getAllDeletedTasks')
    .asFunction();



// C: NativeTask* getAllTasks(int includeDeleted, int* count);
typedef GetAllTasksC = Pointer<NativeTask> Function(Pointer<Int32>);
typedef GetAllTasksDart = Pointer<NativeTask> Function(Pointer<Int32>);

final GetAllTasksDart getAllTasksNative = nativeLib
    .lookup<NativeFunction<GetAllTasksC>>('getAllTasks')
    .asFunction();


//C: NativeTask* getTaskByDate(int date, int* count);
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

/// ====================== UPDATE ======================

// C: int updateTask(int id, const char* title, const char* desc, int date);
final int Function(int, Pointer<Utf8>, Pointer<Utf8>, int)
updateTaskNative = nativeLib
    .lookup<
      NativeFunction<Int32 Function(Int32, Pointer<Utf8>, Pointer<Utf8>, Int32)>
    >('updateTask')
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

// C: void freeTaskMemory(NativeTask* tasks, int count);
final freeTaskMemory = nativeLib
    .lookup<NativeFunction<Void Function(Pointer<NativeTask>, Int32)>>(
      'freeTaskMemory',
    )
    .asFunction<void Function(Pointer<NativeTask>, int)>();


