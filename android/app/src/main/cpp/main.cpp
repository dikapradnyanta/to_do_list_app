#include "sqlite/sqlite3.h"
#include "task/task.h"
#include <stdio.h>
#include <iostream>
#include <vector>
#include <ctime> 
#include <string>



//ga ngaruh, cuma buat contoh aja
int main() {
    Task taskManager;
    taskManager.addTask("Belajar C++", "Mempelajari dasar-dasar C++", 1633036800, "reads"); // Contoh timestamp
    std::cout << "Task added successfully!" << std::endl;
}

// g++ -IC:\sqlite -IC:\Users\Koman\Documents\PROJECT\Developer\Mobile Dev\to_do_list_app\android\app\src\main\cpp\sqlite -LC:\sqlite main.cpp task\task.cpp -lsqlite3 -o output\main.exe