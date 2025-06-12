#include "task.h"
#include "sqlite/sqlite3.h"
#include <fstream>
#include <sstream>
#include <string>
#include <ctime>

// Global Task instance
Task g_task;

Task::Task() {
    // Inisialisasi jika perlu
}

Task::TaskItem::TaskItem(const std::string& id, const std::string& title, const std::string& description, int date)
    : id(id), title(title), description(description), date(date),
      isComplete(false), isDeleted(false) {}

void Task::addTask(const std::string& title, const std::string& description, int date)
{
    sqlite3* db = nullptr;
    char* errMsg = nullptr;

    // Buka database
    if (sqlite3_open("tasks.db", &db) != SQLITE_OK) {
        std::cerr << "Gagal membuka database: " << sqlite3_errmsg(db) << std::endl;
        return;
    }

    // Baca query dari file
    std::ifstream sqlFile("query_sql/db_init.sql");
    if (!sqlFile.is_open()) {
        std::cerr << "Gagal membuka file db_init.sql" << std::endl;
        sqlite3_close(db);
        return;
    }
    std::stringstream buffer;
    buffer << sqlFile.rdbuf();
    std::string sql = buffer.str();

    // Eksekusi query dari file
    if (sqlite3_exec(db, sql.c_str(), nullptr, nullptr, &errMsg) != SQLITE_OK) {
        std::cerr << "SQL error: " << errMsg << std::endl;
        sqlite3_free(errMsg);
        sqlite3_close(db);
        return;
    }

    // Insert tasks
    sqlite3_stmt* stmt = nullptr;
    const char* insertSql = "INSERT INTO task (title, note, timestamp, isComplete, isDeleted) VALUES (?, ?, ?, ?, ?)";
    if (sqlite3_prepare_v2(db, insertSql, -1, &stmt, nullptr) == SQLITE_OK) {
        sqlite3_bind_text(stmt, 1, title.c_str(), -1, SQLITE_STATIC);
        sqlite3_bind_text(stmt, 2, description.c_str(), -1, SQLITE_STATIC);
        sqlite3_bind_int(stmt, 3, date);
        sqlite3_bind_int(stmt, 4, 0); // isComplete (default false)
        sqlite3_bind_int(stmt, 5, 0); // isDeleted (default false)
        if (sqlite3_step(stmt) != SQLITE_DONE) {
            std::cerr << "Gagal insert task" << std::endl;
        } else {
            // Ambil id terakhir yang diinsert (rowid)
            int lastId = (int)sqlite3_last_insert_rowid(db);
            // Simpan ke vector tasks di memori
            tasks.emplace_back(std::to_string(lastId), title, description, date);
            tasks.back().isComplete = false;
            tasks.back().isDeleted = false;
        }
        sqlite3_finalize(stmt);
    } else {
        std::cerr << "Gagal menyiapkan statement insert" << std::endl;
    }

    sqlite3_close(db);
}

int Task::getTask(int id)
{
    // Mengembalikan task berdasarkan ID
    for (const auto& task : tasks) {
        if (std::stoi(task.id) == id && !task.isDeleted) {
            std::cout << "ID: " << task.id << ", Title: " << task.title
                      << ", Description: " << task.description
                      << ", Date: " << task.date
                      << ", Complete: " << (task.isComplete ? "Yes" : "No")
                      << ", Deleted: " << (task.isDeleted ? "Yes" : "No") << std::endl;
            return 0; // Berhasil menemukan task
        }
    }
    std::cout << "Task dengan ID " << id << " tidak ditemukan." << std::endl;
    return -1; // Task tidak ditemukan
}

int Task::getTaskByDate(int date)
{
    // Mengembalikan jumlah task yang ada pada tanggal tertentu
    int count = 0;
    for (const auto& task : tasks) {
        if (task.date == date && !task.isDeleted) {
            count++;
        }
    }
    return count;   
}

int Task::getDoneTaskCount(int date)
{
    // Mengembalikan jumlah task yang sudah selesai pada tanggal tertentu
    int count = 0;
    for (const auto& task : tasks) {
        if (task.isComplete && task.date == date && !task.isDeleted) {
            count++;
        }
    }
    return count;
}

int Task::getAllTasks()
{
    //mengembalikan semua task yang ada di memory
    int count = 0;
    for (const auto& task : tasks) {
        if (!task.isDeleted) { // Hanya tampilkan task yang tidak dihapus
            std::cout << "ID: " << task.id << ", Title: " << task.title
                      << ", Description: " << task.description
                      << ", Date: " << task.date
                      << ", Complete: " << (task.isComplete ? "Yes" : "No")
                      << ", Deleted: " << (task.isDeleted ? "Yes" : "No") << std::endl;
            count++;
        }
    }
    return count;
}

int Task::getDoneTaskCountToday(int date)
{
    //kembalikan jumlah task yang sudah selesai pada hari ini
    int count = 0;
    for (const auto& task : tasks) {
        if (task.isComplete && task.date == date && !task.isDeleted) {
            count++;
        }
    }
    return count;
}

void Task::updateTask(int id, const std::string& title, const std::string& description, int date)
{
    // update task di memory dan simpan log nya
    for (auto& task : tasks) {
        if (std::stoi(task.id) == id) {
            // Cek dan update hanya jika parameter tidak kosong/null
            bool updated = false;
            std::string newTitle = task.title;
            std::string newDescription = task.description;
            int newDate = task.date;

            if (!title.empty()) {
                task.title = title;
                newTitle = title;
                updated = true;
            }
            if (!description.empty()) {
                task.description = description;
                newDescription = description;
                updated = true;
            }
            if (date != 0) {
                task.date = date;
                newDate = date;
                updated = true;
            }

            if (updated) {
                // Simpan log update: id|||title|||note|||timestamp
                std::string logDesc = task.id + "|||" + newTitle + "|||" + newDescription + "|||" + std::to_string(newDate);
                addLog("UPDATE", logDesc);
            }
            break;
        }
    }
}

void Task::changeStatusComplete(int id)
{
    //ubah status task di memory dan simpan log nya
    for (auto& task : tasks) {
        if (std::stoi(task.id) == id) {
            task.isComplete = !task.isComplete; // Toggle status
            // Simpan log perubahan status: id|||title|||note|||timestamp
            std::string logDesc = task.id + "|||" + task.title + "|||" + task.description + "|||" + std::to_string(task.date);
            addLog("UPDATE", logDesc);
            break;
        }
    }
}

void Task::delayTask(int id)
{
    // karena di variabel task berbentuk deque, saya ingin dia deleted task id ini lalu di push ke belakang
    for (auto it = tasks.begin(); it != tasks.end(); ++it) {
        if (std::stoi(it->id) == id) {
            // Simpan log delete: id
            addLog("DELETE", it->id);
            // Simpan data task sebelum dihapus
            TaskItem delayedTask = *it;
            // Hapus task dari vector
            tasks.erase(it);
            // Tambahkan kembali ke belakang
            tasks.push_back(delayedTask);
            // Simpan log insert: title|||note|||timestamp
            std::string logDesc = delayedTask.title + "|||" + delayedTask.description + "|||" + std::to_string(delayedTask.date);
            addLog("INSERT", logDesc);
            break;
        }
    }
}

void Task::deleteTask(int id)
{
    //menandai isDeleted ke true dan simpan log nya
    for (auto& task : tasks) {
        if (std::stoi(task.id) == id) {
            task.isDeleted = true; // Set isDeleted ke true
            // Simpan log delete: id
            addLog("DELETE", task.id);
            break;
        }
    }

}

void Task::restoreTask(int id)
{
    // kembali kan function ini ke fungsi yang sesuai
    for (auto& task : tasks) {
        if (std::stoi(task.id) == id) {
            task.isDeleted = false; // Set isDeleted ke false
            // Simpan log restore: id|||title|||note|||timestamp
            std::string logDesc = task.id + "|||" + task.title + "|||" + task.description + "|||" + std::to_string(task.date);
            addLog("RESTORE", logDesc);
            break;
        }
    }
}

void Task::loadDB() {
    sqlite3* db = nullptr;
    sqlite3_stmt* stmt = nullptr;
    char* errMsg = nullptr;

    tasks.clear(); // Kosongkan vector sebelum load ulang

    if (sqlite3_open("tasks.db", &db) != SQLITE_OK) {
        std::cerr << "Gagal membuka database: " << sqlite3_errmsg(db) << std::endl;
        return;
    }

    const char* selectSql = "SELECT id, title, note, timestamp, isComplete, isDeleted FROM task";
    if (sqlite3_prepare_v2(db, selectSql, -1, &stmt, nullptr) == SQLITE_OK) {
        while (sqlite3_step(stmt) == SQLITE_ROW) {
            std::string id = reinterpret_cast<const char*>(sqlite3_column_text(stmt, 0));
            std::string title = reinterpret_cast<const char*>(sqlite3_column_text(stmt, 1));
            std::string description = reinterpret_cast<const char*>(sqlite3_column_text(stmt, 2));
            int date = sqlite3_column_int(stmt, 3);
            bool isComplete = sqlite3_column_int(stmt, 4) != 0;
            bool isDeleted = sqlite3_column_int(stmt, 5) != 0;

            tasks.emplace_back(id, title, description, date);
            tasks.back().isComplete = isComplete;
            tasks.back().isDeleted = isDeleted;
        }
        sqlite3_finalize(stmt);
    } else {
        std::cerr << "Gagal menyiapkan statement select" << std::endl;
    }

    sqlite3_close(db);
}

void Task::addLog(const std::string& action, const std::string& description) {
    std::ofstream logFile("log.txt", std::ios::app); // mode append
    if (logFile.is_open()) {
        std::time_t now = std::time(nullptr);
        // Format: [timestamp as integer]|||ACTION|||description
        logFile << now << "|||" << action << "|||" << description << std::endl;
        logFile.close();
    }
}

void Task::updateDB() {
    std::ifstream logFile("log.txt");
    if (!logFile.is_open()) {
        std::cerr << "Tidak bisa membuka log.txt" << std::endl;
        return;
    }

    std::string line;
    while (std::getline(logFile, line)) {
        // Format: [timestamp as integer]|||ACTION|||description
        size_t firstDelim = line.find("|||");
        if (firstDelim == std::string::npos) continue;
        size_t secondDelim = line.find("|||", firstDelim + 3);
        if (secondDelim == std::string::npos) continue;

        std::string action = line.substr(firstDelim + 3, secondDelim - (firstDelim + 3));
        std::string description = line.substr(secondDelim + 3);

        if (action == "INSERT") {
            // description: title|||note|||timestamp
            size_t firstSep = description.find("|||");
            size_t secondSep = description.find("|||", firstSep + 3);
            if (firstSep == std::string::npos || secondSep == std::string::npos) continue;

            std::string title = description.substr(0, firstSep);
            std::string note = description.substr(firstSep + 3, secondSep - (firstSep + 3));
            int timestamp = std::stoi(description.substr(secondSep + 3));

            sqlite3* db = nullptr;
            sqlite3_stmt* stmt = nullptr;
            if (sqlite3_open("tasks.db", &db) == SQLITE_OK) {
                const char* insertSql = "INSERT INTO task (title, note, timestamp, isComplete, isDeleted) VALUES (?, ?, ?, 0, 0)";
                if (sqlite3_prepare_v2(db, insertSql, -1, &stmt, nullptr) == SQLITE_OK) {
                    sqlite3_bind_text(stmt, 1, title.c_str(), -1, SQLITE_STATIC);
                    sqlite3_bind_text(stmt, 2, note.c_str(), -1, SQLITE_STATIC);
                    sqlite3_bind_int(stmt, 3, timestamp);
                    sqlite3_step(stmt);
                    sqlite3_finalize(stmt);
                }
                sqlite3_close(db);
            }
        } else if (action == "UPDATE") {
            // description: id|||title|||note|||timestamp
            size_t firstSep = description.find("|||");
            size_t secondSep = description.find("|||", firstSep + 3);
            size_t thirdSep = description.find("|||", secondSep + 3);
            if (firstSep == std::string::npos || secondSep == std::string::npos || thirdSep == std::string::npos) continue;

            std::string id = description.substr(0, firstSep);
            std::string title = description.substr(firstSep + 3, secondSep - (firstSep + 3));
            std::string note = description.substr(secondSep + 3, thirdSep - (secondSep + 3));
            int timestamp = std::stoi(description.substr(thirdSep + 3));

            sqlite3* db = nullptr;
            sqlite3_stmt* stmt = nullptr;
            if (sqlite3_open("tasks.db", &db) == SQLITE_OK) {
                const char* updateSql = "UPDATE task SET title = ?, note = ?, timestamp = ? WHERE id = ?";
                if (sqlite3_prepare_v2(db, updateSql, -1, &stmt, nullptr) == SQLITE_OK) {
                    sqlite3_bind_text(stmt, 1, title.c_str(), -1, SQLITE_STATIC);
                    sqlite3_bind_text(stmt, 2, note.c_str(), -1, SQLITE_STATIC);
                    sqlite3_bind_int(stmt, 3, timestamp);
                    sqlite3_bind_int(stmt, 4, std::stoi(id));
                    sqlite3_step(stmt);
                    sqlite3_finalize(stmt);
                }
                sqlite3_close(db);
            }
        } else if (action == "DELETE") {
            // description: id
            std::string id = description;
            sqlite3* db = nullptr;
            sqlite3_stmt* stmt = nullptr;
            if (sqlite3_open("tasks.db", &db) == SQLITE_OK) {
                const char* deleteSql = "UPDATE task SET isDeleted = 1 WHERE id = ?";
                if (sqlite3_prepare_v2(db, deleteSql, -1, &stmt, nullptr) == SQLITE_OK) {
                    sqlite3_bind_int(stmt, 1, std::stoi(id));
                    sqlite3_step(stmt);
                    sqlite3_finalize(stmt);
                }
                sqlite3_close(db);
            }
        } else if (action == "RESTORE") {
            // description: id|||title|||note|||timestamp
            size_t firstSep = description.find("|||");
            if (firstSep == std::string::npos) continue;
            std::string id = description.substr(0, firstSep);

            sqlite3* db = nullptr;
            sqlite3_stmt* stmt = nullptr;
            if (sqlite3_open("tasks.db", &db) == SQLITE_OK) {
                const char* restoreSql = "UPDATE task SET isDeleted = 0 WHERE id = ?";
                if (sqlite3_prepare_v2(db, restoreSql, -1, &stmt, nullptr) == SQLITE_OK) {
                    sqlite3_bind_int(stmt, 1, std::stoi(id));
                    sqlite3_step(stmt);
                    sqlite3_finalize(stmt);
                }
                sqlite3_close(db);
            }
        }
        // Tambahkan aksi lain sesuai kebutuhan
    }
    logFile.close();

    // Setelah selesai, kosongkan log.txt
    std::ofstream ofs("log.txt", std::ofstream::out | std::ofstream::trunc);
    ofs.close();
}

extern "C" {

int addTask(const char *title, const char *description, int date) {
    g_task.addTask(title, description, date);
    return 1; // return 1 untuk sukses, bisa diubah sesuai kebutuhan
}

int getTask(int id) {
    return g_task.getTask(id);
}

int getTaskByDate(int date) {
    return g_task.getTaskByDate(date);
}

int getDoneTaskCount(int date) {
    return g_task.getDoneTaskCount(date);
}

int getAllTasks() {
    return g_task.getAllTasks();
}

int getDoneTaskCountToday(int date) {
    return g_task.getDoneTaskCountToday(date);
}

int updateTask(int id, const char *title, const char *description, int date) {
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

}

