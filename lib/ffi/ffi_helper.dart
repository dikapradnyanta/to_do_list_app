import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'ffi_bindings.dart';
import '../widgets/task_model.dart';
import 'package:path_provider/path_provider.dart';

// format timestamp to a readable string
String formatTimestamp(int timestamp) {
  final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
  final year = dateTime.year.toString().padLeft(4, '0');
  final month = dateTime.month.toString().padLeft(2, '0');
  final day = dateTime.day.toString().padLeft(2, '0');
  final hour = dateTime.hour.toString().padLeft(2, '0');
  final minute = dateTime.minute.toString().padLeft(2, '0');
  final second = dateTime.second.toString().padLeft(2, '0');
  return '$year/$month/$day $hour:$minute:$second';
}

//Helper Function to get the path of the directory
Future<void> sendLogPathToNative() async {
  final dir = await getApplicationDocumentsDirectory();
  final logPath = '${dir.path}/log.txt';
  final pathPtr = logPath.toNativeUtf8();

  nativeSetLogPath(pathPtr);

  malloc.free(pathPtr);
}

/// ==================== DATABASE ====================
Future<void> initDBWithPathHelper(String dbPath) async {
  final pathPtr = dbPath.toNativeUtf8();
  try {
    initDBWithPathNative(pathPtr); // <-- ini akan dikenali sekarang
  } finally {
    malloc.free(pathPtr);
  }
}

Future<void> initDBHelper() async {
  initDBNative();
}

Future<bool> isDatabaseValidHelper() async {
  final result = isDatabaseValidNative();
  return result == 1;
}

Future<void> setupDatabaseHelper() async {
  setupDatabaseNative();
}

Future<void> loadDBHelper() async {
  loadDBNative();
}

Future<void> updateDBhelper() async {
  try {
    updateDBNative(); // Fungsi ini berasal dari ffi_bindings.dart
  } catch (e) {
    debugPrint('Error in updateDatabaseHelper: $e');
  }
}

/// ==================== CREATE ====================

Future<int> addTaskHelper({
  required String title,
  required String description,
  required int timestamp,
  required String kategori,
}) async {
  debugPrint(
    '[${formatTimestamp(timestamp)}] addTaskHelper: inserting "$title" ',
  );
  final titlePtr = title.toNativeUtf8();
  final descPtr = description.toNativeUtf8();
  final catPtr = kategori.toNativeUtf8();

  final result = addTaskNative(titlePtr, descPtr, timestamp, catPtr);

  calloc.free(titlePtr);
  calloc.free(descPtr);
  calloc.free(catPtr);

  debugPrint('addTaskHelper result: ${result == 1 ? 'success' : 'failure'}');
  return result;
}

/// ==================== READ ====================

Future<int> getTaskHelper(int id) async {
  return getTaskNative(id);
}

Future<List<Task>> getTaskByDateHelper(int date) async {
  final countPtr = calloc<Int32>();

  try {
    final taskPtr = getTaskByDateNative(date, countPtr);
    final count = countPtr.value;

    if (count == 0 || taskPtr == nullptr) {
      return <Task>[];
    }

    final tasks = <Task>[];

    for (int i = 0; i < count; i++) {
      final native = taskPtr.elementAt(i).ref;

      // Safely convert C strings to Dart strings with null checks
      final title = native.title != nullptr ? native.title.toDartString() : '';
      final description = native.description != nullptr
          ? native.description.toDartString()
          : '';
      final category = native.category != nullptr
          ? native.category.toDartString()
          : '';

      tasks.add(
        Task(
          id: native.id,
          title: title,
          description: description,
          timestamp: native.timestamp,
          isComplete: native.isComplete == 1,
          isDeleted: native.isDeleted == 1,
          category: category,
        ),
      );
    }

    // Free native memory - important to prevent memory leaks
    freeTaskMemory(taskPtr, count);

    return tasks;
  } catch (e) {
    // Handle any FFI exceptions
    debugPrint('Error in getTaskByDateHelper: $e');
    return <Task>[];
  } finally {
    calloc.free(countPtr);
  }
}

Future<int> getDoneTaskCountHelper(int date) async {
  try {
    return getDoneTaskCountNative(date);
  } catch (e) {
    debugPrint('Error in getDoneTaskCountHelper: $e');
    return 0;
  }
}

Future<int> getDoneTaskCountTodayHelper(int date) async {
  try {
    return getDoneTaskCountTodayNative(date);
  } catch (e) {
    debugPrint('Error in getDoneTaskCountTodayHelper: $e');
    return 0;
  }
}

Future<int> getTaskCountHelper(int date) async {
  try {
    return getTaskCountNative(date);
  } catch (e) {
    debugPrint('Error in getTaskCountHelper: $e');
    return 0;
  }
}

Future<Task?> getTask(int id) async {
  final result = getTaskNative(id);
  if (result == -1) return null; // asumsi -1 artinya tidak ditemukan
  return null; // update nanti kalau getTask return struct
}

Future<List<Task>> getAllDeletedTasksHelper() async {
  final countPtr = calloc<Int32>();

  try {
    debugPrint("Calling getAllDeletedTasksNative...");
    final tasksPtr = getAllDeletedTasksNative(countPtr);

    final count = countPtr.value;
    debugPrint("Native returned count: $count");

    if (count == 0 || tasksPtr == nullptr) {
      debugPrint("No deleted tasks found.");
      return [];
    }

    final tasks = <Task>[];

    for (int i = 0; i < count; i++) {
      final native = tasksPtr.elementAt(i).ref;

      final title = native.title != nullptr ? native.title.toDartString() : '';
      final description = native.description != nullptr
          ? native.description.toDartString()
          : '';
      final category = native.category != nullptr
          ? native.category.toDartString()
          : '';

      tasks.add(
        Task(
          id: native.id,
          title: title,
          description: description,
          timestamp: native.timestamp,
          isComplete: native.isComplete == 1,
          isDeleted: true, // karena ini dari getAllDeletedTasks
          category: category,
        ),
      );
    }

    freeTaskMemory(tasksPtr, count); // penting kalau alokasi dari C++
    return tasks;
  } catch (e) {
    debugPrint("Error in getAllDeletedTasksHelper: $e");
    return [];
  } finally {
    calloc.free(countPtr);
  }
}



Future<List<Task>> getAllTasksHelper() async {
  //native pointer
  final countPtr = calloc<Int32>(); 

  try {
    debugPrint("Calling getAllTasksNative...");
    final tasksPtr = getAllTasksNative(countPtr);

    final count = countPtr.value;
    debugPrint("Native returned count: $count");

    if (count == 0 || tasksPtr == nullptr) {
      debugPrint("No tasks found.");
      return [];
    }

    final tasks = <Task>[];

    for (int i = 0; i < count; i++) {
      final native = tasksPtr.elementAt(i).ref;

      final title = native.title != nullptr ? native.title.toDartString() : '';
      final description = native.description != nullptr
          ? native.description.toDartString()
          : '';
      final category = native.category != nullptr
          ? native.category.toDartString()
          : '';

      tasks.add(
        Task(
          id: native.id,
          title: title,
          description: description,
          timestamp: native.timestamp,
          isComplete: native.isComplete ==1,
          isDeleted: native.isDeleted == 1,
          category: category,
        ),
      );
    }

    freeTaskMemory(tasksPtr, count); // ✅ cleanup
    return tasks;
  } catch (e) {
    debugPrint("Error in getAllTasksHelper: $e");
    return [];
  } finally {
    calloc.free(countPtr); // ✅ always free
  }
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

  try {
    final result = updateTaskNative(id, titlePtr, descPtr, newTimestamp);
    return result;
  } catch (e) {
    debugPrint('Error in updateTaskHelper: $e');
    return 0;
  } finally {
    malloc.free(titlePtr);
    malloc.free(descPtr);
  }
}

Future<int> changeStatusCompleteHelper(int id) async {
  try {
    return changeStatusCompleteNative(id);
  } catch (e) {
    debugPrint('Error in changeStatusCompleteHelper: $e');
    return 0;
  }
}

Future<int> delayTaskHelper(int id) async {
  try {
    return delayTaskNative(id);
  } catch (e) {
    debugPrint('Error in delayTaskHelper: $e');
    return 0;
  }
}

/// ==================== DELETE / RESTORE ====================

Future<int> deleteTaskHelper(int id) async {
  try {
    return deleteTaskNative(id);
  } catch (e) {
    debugPrint('Error in deleteTaskHelper: $e');
    return 0;
  }
}

Future<int> restoreTaskHelper(int id) async {
  try {
    restoreTaskNative(id); // panggil saja, tanpa return
    return 1; // anggap berhasil
  } catch (e) {
    debugPrint('Error in restoreTaskHelper: $e');
    return 0;
  }
}


/// ==================== UTILITY ====================

/// Check if a task exists and is not deleted
Future<bool> taskExistsHelper(int id) async {
  try {
    final result = await getTaskHelper(id);
    return result == 1;
  } catch (e) {
    debugPrint('Error in taskExistsHelper: $e');
    return false;
  }
}

/// Get task statistics for a specific date
Future<Map<String, int>> getTaskStatsHelper(int date) async {
  try {
    final totalTasks = await getTaskCountHelper(date);
    final doneTasks = await getDoneTaskCountHelper(date);
    final pendingTasks = totalTasks - doneTasks;

    return {'total': totalTasks, 'done': doneTasks, 'pending': pendingTasks};
  } catch (e) {
    debugPrint('Error in getTaskStatsHelper: $e');
    return {'total': 0, 'done': 0, 'pending': 0};
  }
}

/// Initialize database with proper error handling
Future<bool> initializeDatabaseHelper() async {
  try {
    // First, initialize the database
    await initDBHelper();

    // Check if database is valid
    final isValid = await isDatabaseValidHelper();

    if (!isValid) {
      // Setup database if not valid
      await setupDatabaseHelper();
    }

    //replay any pending updates on the database
    await updateDBhelper();
    debugPrint('Replaying pending updates on the database...');
    // Load the database
    await loadDBHelper();

    return true;
  } catch (e) {
    debugPrint('Error initializing database: $e');
    return false;
  }
}

Future<void> insertDummyTasks() async {
  final timestamp = DateTime.now();
  final dayStart =
      DateTime(
        timestamp.year,
        timestamp.month,
        timestamp.day,
      ).millisecondsSinceEpoch ~/
      1000;

  await addTaskHelper(
    title: 'Buy groceries',
    description: 'Milk, Bread, Eggs',
    timestamp: dayStart,
    kategori: 'Food',
  );

  await addTaskHelper(
    title: 'Work on project',
    description: 'Finish UI mockup',
    timestamp: dayStart,
    kategori: 'Work',
  );

  await addTaskHelper(
    title: 'Workout',
    description: '30 min running',
    timestamp: dayStart,
    kategori: 'Sport',
  );
}
