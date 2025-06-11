#ifndef TASK_H
#define TASK_H

#include <iostream>
#include <string>
#include <vector>
#include <ctime>
using namespace std;

class Task {
private:
    struct TaskItem {
        std::string id;
        std::string title;
        std::string description;
        time_t date;
        bool isComplete;
        bool isDeleted;

        TaskItem(const std::string& id, const std::string& title, const std::string& description, time_t date);
    };

    std::vector<TaskItem> tasks;

public:
    //Buiild constructor task 
    Task();

    void addTask(const std::string& title, const std::string& description, time_t date);
    std::string getTitle(const std::string& id);
};

extern "C" int addTask(const char* title, const char* description, int date) {
    // log message
    std::cout << "Title: " << title << std::endl;
    std::cout << "Description: " << description << std::endl;
    std::cout << "Date: " << date << std::endl;

    // Simulasi sukses
    return 1;
}
#endif
