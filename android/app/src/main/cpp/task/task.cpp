// task.cpp (FINAL FFI IMPLEMENTATION)
#include "task.h"
#include <cstring>
#include <vector>
#include <cstdlib>

Task::TaskItem::TaskItem(int id, const std::string& title, const std::string& description, int date, const std::string& category)
  : id(id), title(title), description(description), date(date), isComplete(false), isDeleted(false), category(category) {}

// Global task manager
Task g_task;

// Static buffer for FFI transfer
static std::vector<NativeTask> taskBuffer;

extern "C" {

NativeTask* getTaskByDate(int date, int* count) {
  taskBuffer.clear();
  for (const auto& task : g_task.tasks) {
    if (task.date == date && !task.isDeleted) {
      NativeTask nt;
      nt.id = task.id;
      nt.title = strdup(task.title.c_str());
      nt.description = strdup(task.description.c_str());
      nt.timestamp = task.date;
      nt.isComplete = task.isComplete ? 1 : 0;
      nt.isDeleted = task.isDeleted ? 1 : 0;
      nt.category = strdup(task.category.c_str());
      taskBuffer.push_back(nt);
    }
  }
  *count = static_cast<int>(taskBuffer.size());
  return taskBuffer.data();
}

void freeTaskMemory() {
  for (auto& nt : taskBuffer) {
    free((void*)nt.title);
    free((void*)nt.description);
    free((void*)nt.category);
  }
  taskBuffer.clear();
}

int addTask(const char* title, const char* description, int date, const char* category) {
  static int nextId = 1;
  g_task.tasks.emplace_back(nextId++, title, description, date, category);
  return 1;
}

int getTask(int id) {
  return g_task.getTask(id);
}

int getDoneTaskCount(int date) {
  return g_task.getDoneTaskCount(date);
}

int getAllTasks() {
  return g_task.getAllTasks();
}

int getTaskCount(int date) {
  return g_task.getTaskCount(date);
}

int updateTask(int id, const char* title, const char* description, int date) {
  g_task.updateTask(id, title, description, date);
  return 1;
}

int changeStatusComplete(int id) {
  g_task.changeStatusComplete(id);
  return 1;
}

int delayTask(int id) {
  g_task.delayTask(id);
  return 1;
}

int deleteTask(int id) {
  g_task.deleteTask(id);
  return 1;
}

int restoreTask(int id) {
  g_task.restoreTask(id);
  return 1;
}

} // extern "C"
