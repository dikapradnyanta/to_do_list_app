#ifndef TASK_H
#define TASK_H

#include <iostream>
#include <string>
#include <deque>
#include <ctime>

class Task
{
private:
    struct TaskItem
    {
        std::string id;
        std::string title;
        std::string description;
        int date;
        bool isComplete;
        bool isDeleted;

        TaskItem(const std::string &id, const std::string &title, const std::string &description, int date);
    };

    std::deque<TaskItem> tasks;

public:
    Task();
    /// task management functions
    void loadDB();
    void updateDB();
    void addLog(const std::string &action, const std::string &description);

    // create functions
    void addTask(const std::string &title, const std::string &description, int date);

    // read functions
    int getTask(int id);
    int getTaskByDate(int date);
    int getDoneTaskCount(int date);
    int getAllTasks();
    int getDoneTaskCountToday(int date);

    // write functions
    void updateTask(int id, const std::string &title, const std::string &description, int date);
    void changeStatusComplete(int id);
    void delayTask(int id);

    // delete functions
    void deleteTask(int id);
    void restoreTask(int id);
};

// FFI interface
extern "C"
{
    int addTask(const char *title, const char *description, int date);
    int getTask(int id);
    int getTaskByDate(int date);
    int getDoneTaskCount(int date);
    int getAllTasks();
    int getDoneTaskCountToday(int date);
    int updateTask(int id, const char *title, const char *description, int date);
    int changeStatusComplete(int id);
    int delayTask(int id);
    int deleteTask(int id);
    int restoreTask(int id);
}

#endif
