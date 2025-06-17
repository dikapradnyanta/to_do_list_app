#include "task.h"
#include "../sqlite/sqlite3.h"
#include <fstream>
#include <sstream>
#include <string>
#include <ctime>
#include <vector>
#include <cstring>
#include <cstdlib>
#include <iostream>
#include <android/log.h>

#define LOG_TAG "NativeLog"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

Task g_task;

std::string g_databasePath = "tasks.db";
std::string g_logFilePath = "log.txt";

// ========== UTILITY FUNCTIONS ==========
// Fungsi untuk mengecek dan membuat safe string dari C pointer
std::string safeStringFromCPtr(const char* cstr) {
    if (cstr == nullptr) {
        LOGE("Warning: Received null pointer, returning empty string");
        return "";
    }
    return std::string(cstr);
}

// Fungsi untuk membuat C string dengan pengamanan
char* createCString(const std::string& str) {
    if (str.empty()) {
        char* empty = static_cast<char*>(malloc(1));
        if (empty) {
            empty[0] = '\0';
        }
        return empty;
    }

    size_t len = str.length();
    char* cstr = static_cast<char*>(malloc(len + 1));
    if (!cstr) {
        LOGE("Failed to allocate memory for string: %s", str.c_str());
        return nullptr;
    }

    std::memcpy(cstr, str.c_str(), len);
    cstr[len] = '\0';
    return cstr;
}

// Overload untuk const char*
char* createCString(const char* str) {
    if (str == nullptr) {
        LOGE("Warning: createCString received null pointer");
        char* empty = static_cast<char*>(malloc(1));
        if (empty) {
            empty[0] = '\0';
        }
        return empty;
    }
    return createCString(std::string(str));
}

// ---------- Constructor ----------
Task::TaskItem::TaskItem(int id, const std::string &title, const std::string &description, int date, const std::string &category)
    : id(id), title(title), description(description), date(date), isComplete(false), isDeleted(false), category(category) {}

// ---------- DB Setup ----------
void Task::initDBWithPath(const std::string &dbPath)
{
  LOGI("Initializing database with path: %s", dbPath.c_str());
  g_databasePath = dbPath;
  sqlite3 *db = nullptr;

  if (sqlite3_open(g_databasePath.c_str(), &db) != SQLITE_OK)
    return;

  const char *createTableSQL = R"(
        CREATE TABLE IF NOT EXISTS task (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            note TEXT DEFAULT '',
            timestamp INTEGER NOT NULL,
            isComplete INTEGER DEFAULT 0,
            isDeleted INTEGER DEFAULT 0,
            category TEXT DEFAULT ''
        )
    )";

  char *errMsg = nullptr;
  int result = sqlite3_exec(db, createTableSQL, nullptr, nullptr, &errMsg);

  if (result != SQLITE_OK)
  {
    LOGE("Error creating table: %s", errMsg ? errMsg : "Unknown error");
    if (errMsg) {
        sqlite3_free(errMsg);
    }
  }
  else
  {
    LOGI("Database initialized successfully at: %s", g_databasePath.c_str());
  }
  sqlite3_close(db);
}

void Task::initDB()
{
  initDBWithPath(g_databasePath.c_str());
}

bool Task::isDatabaseValid()
{
  sqlite3 *db = nullptr;
  sqlite3_stmt *stmt = nullptr;
  bool isValid = false;

  if (sqlite3_open(g_databasePath.c_str(), &db) != SQLITE_OK)
    return false;

  const char *checkSQL = "SELECT name FROM sqlite_master WHERE type='table' AND name='task'";
  if (sqlite3_prepare_v2(db, checkSQL, -1, &stmt, nullptr) == SQLITE_OK)
  {
    if (sqlite3_step(stmt) == SQLITE_ROW)
      isValid = true;
    sqlite3_finalize(stmt);
  }

  sqlite3_close(db);
  return isValid;
}

void Task::setupDatabase()
{
  if (!isDatabaseValid())
    initDB();
  loadDB();
}

// ---------- Task Management ----------
void Task::addTask(const std::string &title, const std::string &description, int date, const std::string &category)
{
  sqlite3 *db = nullptr;
  sqlite3_stmt *stmt = nullptr;

  if (sqlite3_open(g_databasePath.c_str(), &db) != SQLITE_OK)
    return;

  const char *insertSQL = "INSERT INTO task (title, note, timestamp, isComplete, isDeleted, category) VALUES (?, ?, ?, 0, 0, ?)";
  if (sqlite3_prepare_v2(db, insertSQL, -1, &stmt, nullptr) == SQLITE_OK)
  {
    sqlite3_bind_text(stmt, 1, title.c_str(), -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(stmt, 2, description.c_str(), -1, SQLITE_TRANSIENT);
    sqlite3_bind_int(stmt, 3, date);
    sqlite3_bind_text(stmt, 4, category.c_str(), -1, SQLITE_TRANSIENT);

    if (sqlite3_step(stmt) == SQLITE_DONE)
    {
      int lastId = static_cast<int>(sqlite3_last_insert_rowid(db));
      tasks.push_back(TaskItem(lastId, title, description, date, category));
      tasks.back().isComplete = false;
      tasks.back().isDeleted = false;
      LOGI("Task added: %s", title.c_str());
    }
    else
    {
      LOGE("Error adding task: %s", sqlite3_errmsg(db));
    }

    sqlite3_finalize(stmt);
  }

  sqlite3_close(db);
}

void Task::updateTask(int id, const std::string &title, const std::string &description, int date)
{
  LOGI("Updating task id=%d with title=%s", id, title.c_str());
  for (auto &task : tasks)
  {
    if (task.id == id)
    {
      task.title = title;
      task.description = description;
      task.date = date;
      std::string logLine = std::to_string(id) + "|||" + title + "|||" + description + "|||" + std::to_string(date);
      addLog("UPDATE", logLine);
      LOGI("Updated task id=%d with title=%s", id, title.c_str());
      break;
    }
  }
}

void Task::deleteTask(int id)
{
  for (auto &task : tasks)
  {
    if (task.id == id)
    {
      task.isDeleted = true;
      LOGI("Deleting task id=%d with title=%s", id, task.title.c_str());
      addLog("DELETE", std::to_string(id));
      break;
    }
  }
}

void Task::restoreTask(int id)
{
  bool found = false;
  for (auto &task : tasks)
  {
    if (task.id == id)
    {
      task.isDeleted = false;
      std::string logLine = std::to_string(id) + "|||" + task.title + "|||" + task.description + "|||" + std::to_string(task.date);
      addLog("RESTORE", logLine);
      LOGI("Restoring task id=%d with title=%s", id, task.title.c_str());
      found = true;
      break;
    }
  }
  
  if (!found)
  {
    LOGE("Task with id=%d not found for restoration", id);
  }
}

void Task::changeStatusComplete(int id)
{
  bool found = false;
  for (auto &task : tasks)
  {
    if (task.id == id)
    {
      task.isComplete = !task.isComplete;
      addLog("STATUS", std::to_string(id) + "|||" + std::to_string(task.isComplete));
      LOGI("Changing status of task id=%d to %s", id, task.isComplete ? "complete" : "incomplete");
      found = true;
      break;
    }
  }

  if (!found)
  {
    LOGE("Task with id=%d not found for status change", id);
  }
}

void Task::delayTask(int id)
{
  bool found = false;
  for (auto it = tasks.begin(); it != tasks.end(); ++it)
  {
    if (it->id == id)
    {
      TaskItem moved = *it;
      tasks.erase(it);
      tasks.push_back(moved);
      addLog("DELETE", std::to_string(id));
      addLog("INSERT", moved.title + "|||" + moved.description + "|||" + std::to_string(moved.date));
      found = true;
      break;
    }
  }
  
  if (!found)
  {
    LOGE("Task with id=%d not found for delay", id);
  }
}

// ---------- Getters ----------
int Task::getTask(int id)
{
  for (const auto &task : tasks)
  {
    if (task.id == id && !task.isDeleted)
      return 1;
  }
  return 0;
}

std::vector<Task::TaskItem> Task::getTasksByDate(int date)
{
  std::vector<TaskItem> result;
  for (const auto &task : tasks)
  {
    if (task.date >= date && task.date < date + 86400 && !task.isDeleted)
    {
      result.push_back(task);
    }
  }
  return result;
}

std::vector<Task::TaskItem> Task::getAllTasks(bool includeDeleted)
{
  std::vector<TaskItem> result;
  for (const auto &task : tasks)
  {
    if (includeDeleted || !task.isDeleted)
    {
      result.push_back(task);
    }
  }
  return result;
}

int Task::getTaskCount(int date)
{
  int count = 0;
  for (const auto &task : tasks)
  {
    if (task.date >= date && task.date < date + 86400 && !task.isDeleted)
    {
      count++;
    }
  }
  return count;
}

int Task::getDoneTaskCount(int date)
{
  int count = 0;
  for (const auto &task : tasks)
  {
    if (task.date >= date && task.date < date + 86400 && task.isComplete && !task.isDeleted)
    {
      count++;
    }
  }
  return count;
}

int Task::getDoneTaskCountToday(int date)
{
  return getDoneTaskCount(date);
}

// ---------- Database I/O ----------
void Task::loadDB()
{
  sqlite3 *db = nullptr;
  if (sqlite3_open(g_databasePath.c_str(), &db) != SQLITE_OK)
  {
    LOGE("Failed to open database: %s", sqlite3_errmsg(db));
    return;
  }

  const char *sql = "SELECT id, title, note, timestamp, isComplete, isDeleted, category FROM task";
  sqlite3_stmt *stmt = nullptr;

  if (sqlite3_prepare_v2(db, sql, -1, &stmt, nullptr) == SQLITE_OK)
  {
    tasks.clear();

    while (sqlite3_step(stmt) == SQLITE_ROW)
    {
      int id = sqlite3_column_int(stmt, 0);

      const char *title = (const char *)sqlite3_column_text(stmt, 1);
      std::string titleStr = safeStringFromCPtr(title);

      const char *note = (const char *)sqlite3_column_text(stmt, 2);
      std::string noteStr = safeStringFromCPtr(note);

      int timestamp = sqlite3_column_int(stmt, 3);
      bool isComplete = sqlite3_column_int(stmt, 4) == 1;
      bool isDeleted = sqlite3_column_int(stmt, 5) == 1;

      const char *category = (const char *)sqlite3_column_text(stmt, 6);
      std::string categoryStr = safeStringFromCPtr(category);

      TaskItem task(id, titleStr, noteStr, timestamp, categoryStr);
      task.isComplete = isComplete;
      task.isDeleted = isDeleted;

      tasks.push_back(task);

      LOGI("Loaded task: id=%d, title=%s, complete=%d, deleted=%d",
           id, titleStr.c_str(), isComplete, isDeleted);
    }

    sqlite3_finalize(stmt);
    LOGI("Successfully loaded %zu tasks from database", tasks.size());
  }
  else
  {
    LOGE("Failed to prepare select statement: %s", sqlite3_errmsg(db));
  }

  sqlite3_close(db);
}

void Task::updateDB()
{
  if (g_logFilePath.empty())
  {
    LOGE("Log file path is not set, cannot update database");
    return;
  }

  std::ifstream logFile(g_logFilePath);
  if (!logFile.is_open())
  {
    LOGI("No log file found or failed to open: %s", g_logFilePath.c_str());
    return;
  }

  sqlite3 *db = nullptr;
  if (sqlite3_open(g_databasePath.c_str(), &db) != SQLITE_OK)
  {
    LOGE("Failed to open database: %s", sqlite3_errmsg(db));
    logFile.close();
    return;
  }

  std::string line;
  int processedLines = 0;

  while (std::getline(logFile, line))
  {
    if (line.empty())
      continue;

    size_t timeEnd = line.find("|||");
    size_t actEnd = line.find("|||", timeEnd + 3);
    if (timeEnd == std::string::npos || actEnd == std::string::npos)
    {
      LOGE("Invalid log line format: %s", line.c_str());
      continue;
    }

    std::string timestamp = line.substr(0, timeEnd);
    std::string action = line.substr(timeEnd + 3, actEnd - (timeEnd + 3));
    std::string desc = line.substr(actEnd + 3);

    sqlite3_stmt *stmt = nullptr;
    bool success = false;

    try
    {
      if (action == "UPDATE")
      {
        size_t a = desc.find("|||");
        size_t b = desc.find("|||", a + 3);
        size_t c = desc.find("|||", b + 3);

        if (a != std::string::npos && b != std::string::npos && c != std::string::npos)
        {
          int id = std::stoi(desc.substr(0, a));
          std::string title = desc.substr(a + 3, b - (a + 3));
          std::string note = desc.substr(b + 3, c - (b + 3));
          int newTimestamp = std::stoi(desc.substr(c + 3));

          const char *sql = "UPDATE task SET title = ?, note = ?, timestamp = ? WHERE id = ?";
          if (sqlite3_prepare_v2(db, sql, -1, &stmt, nullptr) == SQLITE_OK)
          {
            sqlite3_bind_text(stmt, 1, title.c_str(), -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(stmt, 2, note.c_str(), -1, SQLITE_TRANSIENT);
            sqlite3_bind_int(stmt, 3, newTimestamp);
            sqlite3_bind_int(stmt, 4, id);

            if (sqlite3_step(stmt) == SQLITE_DONE)
            {              
              success = true;
              LOGI("Updated task %d: %s", id, title.c_str());
            }
            else
            {
              LOGE("Failed to update task %d: %s", id, sqlite3_errmsg(db));
            }
          }
        }
      }
      else if (action == "DELETE")
      {
        int id = std::stoi(desc);
        const char *sql = "UPDATE task SET isDeleted = 1 WHERE id = ?";
        if (sqlite3_prepare_v2(db, sql, -1, &stmt, nullptr) == SQLITE_OK)
        {
          sqlite3_bind_int(stmt, 1, id);

          if (sqlite3_step(stmt) == SQLITE_DONE)
          {
            success = true;
            LOGI("Deleted task %d", id);
          }
          else
          {
            LOGE("Failed to delete task %d: %s", id, sqlite3_errmsg(db));
          }
        }
      }
      else if (action == "RESTORE")
      {
        size_t idEnd = desc.find("|||");
        if (idEnd != std::string::npos)
        {
          int id = std::stoi(desc.substr(0, idEnd));
          const char *sql = "UPDATE task SET isDeleted = 0 WHERE id = ?";
          if (sqlite3_prepare_v2(db, sql, -1, &stmt, nullptr) == SQLITE_OK)
          {
            sqlite3_bind_int(stmt, 1, id);

            if (sqlite3_step(stmt) == SQLITE_DONE)
            {
              success = true;
              LOGI("Restored task %d", id);
            }
            else
            {
              LOGE("Failed to restore task %d: %s", id, sqlite3_errmsg(db));
            }
          }
        }
      }
      else if (action == "STATUS")
      {
        size_t a = desc.find("|||");
        if (a != std::string::npos)
        {
          int id = std::stoi(desc.substr(0, a));
          bool isComplete = std::stoi(desc.substr(a + 3)) != 0;

          const char *sql = "UPDATE task SET isComplete = ? WHERE id = ?";
          if (sqlite3_prepare_v2(db, sql, -1, &stmt, nullptr) == SQLITE_OK)
          {
            sqlite3_bind_int(stmt, 1, isComplete ? 1 : 0);
            sqlite3_bind_int(stmt, 2, id);

            if (sqlite3_step(stmt) == SQLITE_DONE)
            {
              success = true;
              LOGI("Updated status for task %d: %s", id, isComplete ? "complete" : "incomplete");
            }
            else
            {
              LOGE("Failed to update task status %d: %s", id, sqlite3_errmsg(db));
            }
          }
        }
      }
      else if (action == "INSERT")
      {
        size_t a = desc.find("|||");
        size_t b = desc.find("|||", a + 3);
        size_t c = desc.find("|||", b + 3);

        if (a != std::string::npos && b != std::string::npos && c != std::string::npos)
        {
          std::string title = desc.substr(0, a);
          std::string note = desc.substr(a + 3, b - (a + 3));
          int timestamp = std::stoi(desc.substr(b + 3, c - (b + 3)));
          std::string category = desc.substr(c + 3);

          const char *sql = "INSERT INTO task (title, note, timestamp, isComplete, isDeleted, category) VALUES (?, ?, ?, 0, 0, ?)";
          if (sqlite3_prepare_v2(db, sql, -1, &stmt, nullptr) == SQLITE_OK)
          {
            sqlite3_bind_text(stmt, 1, title.c_str(), -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(stmt, 2, note.c_str(), -1, SQLITE_TRANSIENT);
            sqlite3_bind_int(stmt, 3, timestamp);
            sqlite3_bind_text(stmt, 4, category.c_str(), -1, SQLITE_TRANSIENT);

            if (sqlite3_step(stmt) == SQLITE_DONE)
            {
              success = true;
              LOGI("Added task: %s", title.c_str());
            }
            else
            {
              LOGE("Failed to add task: %s", sqlite3_errmsg(db));
            }
          }
        }
      }
      else
      {
        LOGE("Unknown action: %s", action.c_str());
      }

      if (stmt)
      {
        sqlite3_finalize(stmt);
        stmt = nullptr;
      }

      if (success)
      {
        processedLines++;
      }
    }
    catch (const std::exception &e)
    {
      LOGE("Error processing log line '%s': %s", line.c_str(), e.what());
      if (stmt)
      {
        sqlite3_finalize(stmt);
        stmt = nullptr;
      }
    }
  }

  logFile.close();
  sqlite3_close(db);

  LOGI("Processed %d log entries", processedLines);

  if (processedLines > 0)
  {
    std::ofstream ofs(g_logFilePath, std::ofstream::trunc);
    if (ofs.is_open())
    {
      ofs.close();
      LOGI("Cleared log file after processing");
    }
    else
    {
      LOGE("Failed to clear log file: %s", g_logFilePath.c_str());
    }
  }
}

void Task::addLog(const std::string &action, const std::string &desc)
{
  if (g_logFilePath.empty())
  {
    LOGE("Log file path is not set!");
    return;
  }

  std::ofstream file(g_logFilePath, std::ios::app);
  if (!file.is_open())
  {
    LOGE("Failed to open log file for writing: %s", g_logFilePath.c_str());
    return;
  }

  std::time_t now = std::time(nullptr);
  file << now << "|||" << action << "|||" << desc << std::endl;

  if (file.fail())
  {
    LOGE("Failed to write to log file");
  }
  else
  {
    LOGI("Log written: %ld|||%s|||%s", now, action.c_str(), desc.c_str());
  }

  file.close();
}

// ============== C EXPORTS FOR FFI ==============
extern "C"
{
  void setLogFilePath(const char *path)
  {
    if (path != nullptr)
    {
      g_logFilePath = safeStringFromCPtr(path);
      LOGI("Log file path set to: %s", g_logFilePath.c_str());
    }
    else
    {
      LOGE("setLogFilePath: Received null path pointer");
    }
  }

  void initDBWithPath(const char *path)
  {
    if (path != nullptr)
    {
      g_task.initDBWithPath(safeStringFromCPtr(path));
    }
    else
    {
      LOGE("initDBWithPath: Received null path pointer");
    }
  }
  
  void initDB()
  {
    g_task.initDB();
  }

  int isDatabaseValid()
  {
    return g_task.isDatabaseValid() ? 1 : 0;
  }

  void setupDatabase()
  {
    g_task.setupDatabase();
  }

  void loadDB()
  {
    g_task.loadDB();
  }

  int addTask(const char *title, const char *description, int date, const char *category)
  {
    // Validasi null pointer
    if (title == nullptr || description == nullptr || category == nullptr)
    {
      LOGE("addTask: Received null pointer(s) - title=%p, description=%p, category=%p", 
           (void*)title, (void*)description, (void*)category);
      return 0;
    }
    
    std::string safeTitle = safeStringFromCPtr(title);
    std::string safeDescription = safeStringFromCPtr(description);
    std::string safeCategory = safeStringFromCPtr(category);
    
    g_task.addTask(safeTitle, safeDescription, date, safeCategory);
    return 1;
  }

  int getTask(int id)
  {
    return g_task.getTask(id);
  }

  NativeTask *getTaskByDate(int date, int *count)
  {
    if (count == nullptr)
    {
      LOGE("getTaskByDate: count pointer is null");
      return nullptr;
    }

    std::vector<Task::TaskItem> tasks = g_task.getTasksByDate(date);
    *count = static_cast<int>(tasks.size());

    if (tasks.empty())
    {
      return nullptr;
    }

    NativeTask *nativeTasks = static_cast<NativeTask *>(malloc(sizeof(NativeTask) * tasks.size()));
    if (!nativeTasks)
    {
      LOGE("getTaskByDate: Failed to allocate memory");
      *count = 0;
      return nullptr;
    }

    for (size_t i = 0; i < tasks.size(); i++)
    {
      nativeTasks[i].id = tasks[i].id;
      nativeTasks[i].title = createCString(tasks[i].title);
      nativeTasks[i].description = createCString(tasks[i].description);
      nativeTasks[i].timestamp = tasks[i].date;
      nativeTasks[i].isComplete = tasks[i].isComplete ? 1 : 0;
      nativeTasks[i].isDeleted = tasks[i].isDeleted ? 1 : 0;
      nativeTasks[i].category = createCString(tasks[i].category);
      
      // Validasi alokasi memori
      if (!nativeTasks[i].title || !nativeTasks[i].description || !nativeTasks[i].category)
      {
        LOGE("getTaskByDate: Failed to allocate memory for task %zu", i);
        // Cleanup yang sudah berhasil dialokasi
        for (size_t j = 0; j <= i; j++)
        {
          if (nativeTasks[j].title) free(nativeTasks[j].title);
          if (nativeTasks[j].description) free(nativeTasks[j].description);
          if (nativeTasks[j].category) free(nativeTasks[j].category);
        }
        free(nativeTasks);
        *count = 0;
        return nullptr;
      }
    }

    return nativeTasks;
  }

  int getDoneTaskCount(int date)
  {
    return g_task.getDoneTaskCount(date);
  }

  int getDoneTaskCountToday(int date)
  {
    return g_task.getDoneTaskCountToday(date);
  }

  int getTaskCount(int date)
  {
    return g_task.getTaskCount(date);
  }

  NativeTask *getAllTasks(int *count)
  {
    if (count == nullptr)
    {
      LOGE("getAllTasks: count pointer is null!");
      return nullptr;
    }

    g_task.loadDB();

    std::vector<Task::TaskItem> rawTasks = g_task.getAllTasks(false);
    *count = static_cast<int>(rawTasks.size());

    if (*count == 0)
    {
      LOGI("getAllTasks: No tasks found.");
      return nullptr;
    }

    NativeTask *result = static_cast<NativeTask *>(malloc(sizeof(NativeTask) * (*count)));
    if (!result)
    {
      LOGE("getAllTasks: Failed to allocate memory.");
      *count = 0;
      return nullptr;
    }

    for (int i = 0; i < *count; ++i)
    {
      const Task::TaskItem &t = rawTasks[i];

      result[i].id = t.id;
      result[i].title = createCString(t.title);
      result[i].description = createCString(t.description);
      result[i].timestamp = t.date;
      result[i].isComplete = t.isComplete ? 1 : 0;
      result[i].isDeleted = t.isDeleted ? 1 : 0;
      result[i].category = createCString(t.category);
      
      // Validasi alokasi memori
      if (!result[i].title || !result[i].description || !result[i].category)
      {
        LOGE("getAllTasks: Failed to allocate memory for task %d", i);
        // Cleanup
        for (int j = 0; j <= i; j++)
        {
          if (result[j].title) free(result[j].title);
          if (result[j].description) free(result[j].description);
          if (result[j].category) free(result[j].category);
        }
        free(result);
        *count = 0;
        return nullptr;
      }
    }

    return result;
  }
  NativeTask *getAllDeletedTasks(int *count)
  {
    if (count == nullptr)
    {
      LOGE("getAllTasks: count pointer is null!");
      return nullptr;
    }

    g_task.loadDB();

    std::vector<Task::TaskItem> rawTasks = g_task.getAllTasks(true);
    *count = static_cast<int>(rawTasks.size());

    if (*count == 0)
    {
      LOGI("getAllTasks: No tasks found.");
      return nullptr;
    }

    NativeTask *result = static_cast<NativeTask *>(malloc(sizeof(NativeTask) * (*count)));
    if (!result)
    {
      LOGE("getAllTasks: Failed to allocate memory.");
      *count = 0;
      return nullptr;
    }

    for (int i = 0; i < *count; ++i)
    {
      const Task::TaskItem &t = rawTasks[i];

      result[i].id = t.id;
      result[i].title = createCString(t.title);
      result[i].description = createCString(t.description);
      result[i].timestamp = t.date;
      result[i].isComplete = t.isComplete ? 1 : 0;
      result[i].isDeleted = t.isDeleted ? 1 : 0;
      result[i].category = createCString(t.category);
      
      // Validasi alokasi memori
      if (!result[i].title || !result[i].description || !result[i].category)
      {
        LOGE("getAllTasks: Failed to allocate memory for task %d", i);
        // Cleanup
        for (int j = 0; j <= i; j++)
        {
          if (result[j].title) free(result[j].title);
          if (result[j].description) free(result[j].description);
          if (result[j].category) free(result[j].category);
        }
        free(result);
        *count = 0;
        return nullptr;
      }
    }

    return result;
  }


  int updateTask(int id, const char *title, const char *description, int date)
  {
    if (title == nullptr || description == nullptr)
    {
      LOGE("updateTask: Received null pointer(s) - title=%p, description=%p", 
           (void*)title, (void*)description);
      return 0;
    }
    
    std::string safeTitle = safeStringFromCPtr(title);
    std::string safeDescription = safeStringFromCPtr(description);
    
    g_task.updateTask(id, safeTitle, safeDescription, date);
    return 1;
  }

  int changeStatusComplete(int id)
  {
    g_task.changeStatusComplete(id);
    return 1;
  }

  int delayTask(int id)
  {
    g_task.delayTask(id);
    return 1;
  }
  int deleteTask(int id)
  {
    g_task.deleteTask(id);
    return 1;
  }

  int restoreTask(int id)
  {
    g_task.restoreTask(id);
    return 1;
  }

  void freeTaskMemory(NativeTask *tasks, int count)
  {
    if (!tasks)
      return;

    for (int i = 0; i < count; ++i)
    {
      if (tasks[i].title)
        free(tasks[i].title);
      if (tasks[i].description)
        free(tasks[i].description);
      if (tasks[i].category)
        free(tasks[i].category);
    }
    free(tasks);
  }

  void updateDB()
  {
    g_task.updateDB();
  }

}