#include <stdio.h>
#include <task.h>

//ga ngaruh, cuma buat contoh aja
int main() {
    Task taskManager;

    // Example usage
    taskManager.addTask("1", "Task 1", "Description for Task 1", time(nullptr));
    taskManager.addTask("2", "Task 2", "Description for Task 2", time(nullptr));

    printf("Title of Task 1: %s\n", taskManager.getTitle("1").c_str());
    printf("Title of Task 2: %s\n", taskManager.getTitle("2").c_str());
    printf("Title of Non-existent Task: %s\n", taskManager.getTitle("3").c_str());

    return 0;
}