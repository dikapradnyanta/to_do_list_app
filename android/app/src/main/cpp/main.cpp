#include <stdio.h>
#include <ctime> 
#include <string>
#include "task/task.h"

//ga ngaruh, cuma buat contoh aja
int main() {
    Task taskManager;

    // Example usage
    // Ensure the arguments match the expected types and order in addTask
    // For example, if addTask expects (const char* id, const char* title, time_t dueDate, const char* description)
    taskManager.addTask("fufufafa", "Task 1",time(nullptr));

    return 0;
}