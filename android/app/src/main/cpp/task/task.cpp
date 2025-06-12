#include "task.h"
#include "sqlite/sqlite3.h"
#include <fstream>
#include <sstream>
#include <string>
#include <ctime>

Task::TaskItem::TaskItem(int id, const std::string& title, const std::string& description, int date, const std::string& category)
  : id(id), title(title), description(description), date(date), isComplete(false), isDeleted(false), category(category) {}

Task g_task;

void Task::addTask(const std::string& title, const std::string& description, int date, const std::string& category) {
  sqlite3* db = nullptr;
  sqlite3_stmt* stmt = nullptr;

  if (sqlite3_open("tasks.db", &db) != SQLITE_OK) return;

  const char* insertSQL = "INSERT INTO task (title, note, timestamp, isComplete, isDeleted, category) VALUES (?, ?, ?, 0, 0, ?)";
  if (sqlite3_prepare_v2(db, insertSQL, -1, &stmt, nullptr) == SQLITE_OK) {
    sqlite3_bind_text(stmt, 1, title.c_str(), -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(stmt, 2, description.c_str(), -1, SQLITE_TRANSIENT);
    sqlite3_bind_int(stmt, 3, date);
    sqlite3_bind_text(stmt, 4, category.c_str(), -1, SQLITE_TRANSIENT);

    if (sqlite3_step(stmt) == SQLITE_DONE) {
      int lastId = (int)sqlite3_last_insert_rowid(db);
      tasks.emplace_back(lastId, title, description, date, category);
    }

    sqlite3_finalize(stmt);
  }

  sqlite3_close(db);
}

int Task::getTask(int id) {
  for (const auto& task : tasks) {
    if (task.id == id && !task.isDeleted) {
      return 1;
    }
  }
  return 0;
}

int Task::getTaskByDate(int date) {
  int count = 0;
  for (const auto& task : tasks) {
    if (task.date == date && !task.isDeleted) count++;
  }
  return count;
}

int Task::getDoneTaskCount(int date) {
  int count = 0;
  for (const auto& task : tasks) {
    if (task.date == date && task.isComplete && !task.isDeleted) count++;
  }
  return count;
}

int Task::getAllTasks() {
  int count = 0;
  for (const auto& task : tasks) {
    if (!task.isDeleted) count++;
  }
  return count;
}

int Task::getTaskCount(int date) {
  int count = 0;
  for (const auto& task : tasks) {
    if (task.date == date && !task.isDeleted) count++;
  }
  return count;
}

void Task::updateTask(int id, const std::string& title, const std::string& description, int date) {
  for (auto& task : tasks) {
    if (task.id == id) {
      task.title = title;
      task.description = description;
      task.date = date;

      std::string logLine = std::to_string(id) + "|||" + title + "|||" + description + "|||" + std::to_string(date);
      addLog("UPDATE", logLine);
      break;
    }
  }
}

void Task::changeStatusComplete(int id) {
  for (auto& task : tasks) {
    if (task.id == id) {
      task.isComplete = !task.isComplete;
      std::string logLine = std::to_string(task.id) + "|||" + task.title + "|||" + task.description + "|||" + std::to_string(task.date);
      addLog("UPDATE", logLine);
      break;
    }
  }
}

void Task::delayTask(int id) {
  for (auto it = tasks.begin(); it != tasks.end(); ++it) {
    if (it->id == id) {
      TaskItem moved = *it;
      tasks.erase(it);
      tasks.push_back(moved);

      addLog("DELETE", std::to_string(id));
      addLog("INSERT", moved.title + "|||" + moved.description + "|||" + std::to_string(moved.date));
      break;
    }
  }
}

void Task::deleteTask(int id) {
  for (auto& task : tasks) {
    if (task.id == id) {
      task.isDeleted = true;
      addLog("DELETE", std::to_string(id));
      break;
    }
  }
}

void Task::restoreTask(int id) {
  for (auto& task : tasks) {
    if (task.id == id) {
      task.isDeleted = false;
      std::string logLine = std::to_string(id) + "|||" + task.title + "|||" + task.description + "|||" + std::to_string(task.date);
      addLog("RESTORE", logLine);
      break;
    }
  }
}

void Task::loadDB() {
  sqlite3* db = nullptr;
  sqlite3_stmt* stmt = nullptr;
  tasks.clear();

  if (sqlite3_open("tasks.db", &db) != SQLITE_OK) return;

  const char* sql = "SELECT id, title, note, timestamp, isComplete, isDeleted, category FROM task";
  if (sqlite3_prepare_v2(db, sql, -1, &stmt, nullptr) == SQLITE_OK) {
    while (sqlite3_step(stmt) == SQLITE_ROW) {
      int id = sqlite3_column_int(stmt, 0);
      std::string title = reinterpret_cast<const char*>(sqlite3_column_text(stmt, 1));
      std::string desc = reinterpret_cast<const char*>(sqlite3_column_text(stmt, 2));
      int date = sqlite3_column_int(stmt, 3);
      bool complete = sqlite3_column_int(stmt, 4);
      bool deleted = sqlite3_column_int(stmt, 5);
      std::string category = reinterpret_cast<const char*>(sqlite3_column_text(stmt, 6));

      tasks.emplace_back(id, title, desc, date, category);
      tasks.back().isComplete = complete;
      tasks.back().isDeleted = deleted;
    }
    sqlite3_finalize(stmt);
  }

  sqlite3_close(db);
}

void Task::updateDB() {
  std::ifstream logFile("log.txt");
  if (!logFile.is_open()) return;

  std::string line;
  while (std::getline(logFile, line)) {
    size_t first = line.find("|||");
    size_t second = line.find("|||", first + 3);
    if (first == std::string::npos || second == std::string::npos) continue;

    std::string action = line.substr(first + 3, second - (first + 3));
    std::string desc = line.substr(second + 3);

    sqlite3* db = nullptr;
    sqlite3_stmt* stmt = nullptr;
    sqlite3_open("tasks.db", &db);

    if (action == "UPDATE") {
      size_t a = desc.find("|||");
      size_t b = desc.find("|||", a + 3);
      size_t c = desc.find("|||", b + 3);

      if (a != std::string::npos && b != std::string::npos && c != std::string::npos) {
        int id = std::stoi(desc.substr(0, a));
        std::string title = desc.substr(a + 3, b - (a + 3));
        std::string note = desc.substr(b + 3, c - (b + 3));
        int timestamp = std::stoi(desc.substr(c + 3));

        const char* sql = "UPDATE task SET title = ?, note = ?, timestamp = ? WHERE id = ?";
        if (sqlite3_prepare_v2(db, sql, -1, &stmt, nullptr) == SQLITE_OK) {
          sqlite3_bind_text(stmt, 1, title.c_str(), -1, SQLITE_STATIC);
          sqlite3_bind_text(stmt, 2, note.c_str(), -1, SQLITE_STATIC);
          sqlite3_bind_int(stmt, 3, timestamp);
          sqlite3_bind_int(stmt, 4, id);
          sqlite3_step(stmt);
          sqlite3_finalize(stmt);
        }
      }
    }
    else if (action == "DELETE") {
      int id = std::stoi(desc);
      const char* sql = "UPDATE task SET isDeleted = 1 WHERE id = ?";
      if (sqlite3_prepare_v2(db, sql, -1, &stmt, nullptr) == SQLITE_OK) {
        sqlite3_bind_int(stmt, 1, id);
        sqlite3_step(stmt);
        sqlite3_finalize(stmt);
      }
    }
    else if (action == "RESTORE") {
      int id = std::stoi(desc.substr(0, desc.find("|||")));
      const char* sql = "UPDATE task SET isDeleted = 0 WHERE id = ?";
      if (sqlite3_prepare_v2(db, sql, -1, &stmt, nullptr) == SQLITE_OK) {
        sqlite3_bind_int(stmt, 1, id);
        sqlite3_step(stmt);
        sqlite3_finalize(stmt);
      }
    }

    sqlite3_close(db);
  }

  logFile.close();
  std::ofstream ofs("log.txt", std::ofstream::out | std::ofstream::trunc);
  ofs.close();
}

void Task::addLog(const std::string& action, const std::string& desc) {
  std::ofstream file("log.txt", std::ios::app);
  if (file.is_open()) {
    std::time_t now = std::time(nullptr);
    file << now << "|||" << action << "|||" << desc << std::endl;
    file.close();
  }
}

