#ifndef TASK_H
#define TASK_H

#include <string>
#include <deque>
#include <vector>

#ifdef __cplusplus
extern "C" {
#endif

// struct NativeTask for FFI compatibility
typedef struct {
    int id;
    char* title;
    char* description;
    int timestamp;      
    int isComplete;
    int isDeleted;
    char* category;
} NativeTask;

// database management functions
void initDBWithPath(const char* path);
void initDB();
int isDatabaseValid();
void setupDatabase();
void loadDB();

int addTask(const char* title, const char* description, int date, const char* category);
int getTask(int id);
NativeTask* getTaskByDate(int date, int* count);
NativeTask* getAllTasks(int* count);  
int getDoneTaskCount(int date);
int getDoneTaskCountToday(int date);
int getTaskCount(int date);
int getAllTaskCount();  

int updateTask(int id, const char* title, const char* description, int date);
int changeStatusComplete(int id);
int delayTask(int id);

int deleteTask(int id);
int restoreTask(int id);
void freeTaskMemory(NativeTask* tasks, int count);

#ifdef __cplusplus
}
#endif

// ✅ Class C++ tetap di luar extern "C"
class Task {
public:
    std::string dbPath;
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

    void initDBWithPath(const std::string& dbPath);
    void initDB();
    bool isDatabaseValid();
    void setupDatabase();

    void addTask(const std::string& title, const std::string& description, int date, const std::string& category);
    int getTask(int id);
    std::vector<TaskItem> getTasksByDate(int date);
    std::vector<TaskItem> getAllTasks(bool includeDeleted);
    int getDoneTaskCount(int date);
    int getDoneTaskCountToday(int date);
    int getTaskCount(int date);
    void updateTask(int id, const std::string& title, const std::string& description, int date);
    void changeStatusComplete(int id);
    void delayTask(int id);
    void deleteTask(int id);
    void restoreTask(int id);

    void loadDB();
    void updateDB();
    static void setLogFilePath(const char* path);
private:
    void addLog(const std::string& action, const std::string& description);
};

// Global instance untuk akses dari luar
extern Task g_task;

#endif // TASK_H
