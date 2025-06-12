// task.h (FINAL)
#ifndef TASK_H
#define TASK_H

#include <string>
#include <deque>
#include <vector>

// NativeTask struct for FFI
extern "C" {
  struct NativeTask {
    int id;
    const char* title;
    const char* description;
    int timestamp;
    int isComplete;
    int isDeleted;
    const char* category;
  };
}

class Task {
public:
  struct TaskItem {
    int id;
    std::string title;
    std::string description;
    int date;
    bool isComplete;
    bool isDeleted;
    std::string category;

    TaskItem(int id, const std::string& title, const std::string& description, int date, const std::string& category);
  };

  std::deque<TaskItem> tasks;

  void addTask(const std::string& title, const std::string& description, int date, const std::string& category);
  int getTask(int id);
  int getTaskByDate(int date);
  int getDoneTaskCount(int date);
  int getAllTasks();
  int getTaskCount(int date);
  void updateTask(int id, const std::string& title, const std::string& description, int date);
  void changeStatusComplete(int id);
  void delayTask(int id);
  void deleteTask(int id);
  void restoreTask(int id);
  void loadDB();
  void updateDB();

private:
  void addLog(const std::string& action, const std::string& description);
};

// Exposed for FFI
extern "C" {
  NativeTask* getTaskByDate(int date, int* count);
  void freeTaskMemory();
  int addTask(const char* title, const char* description, int date, const char* category);
  int getTask(int id);
  int getDoneTaskCount(int date);
  int getAllTasks();
  int getTaskCount(int date);
  int updateTask(int id, const char* title, const char* description, int date);
  int changeStatusComplete(int id);
  int delayTask(int id);
  int deleteTask(int id);
  int restoreTask(int id);
}

#endif // TASK_H
