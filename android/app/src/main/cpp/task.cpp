#include "task.h"
#include "sqlite/sqlite3.h"
#include <iostream>
#include <fstream>
#include <sstream>
#include <string>

Task::Task() {}

Task::TaskItem::TaskItem(const std::string& id, const std::string& title, const std::string& description, time_t date)
    : id(id), title(title), description(description), date(date),
      isComplete(false), isDeleted(false) {}

void Task::addTask(const std::string& title, const std::string& description, time_t date)
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

    // Insert task
    sqlite3_stmt* stmt = nullptr;
    const char* insertSql = "INSERT INTO task (title, note, timestamp) VALUES (?, ?, ?)";
    if (sqlite3_prepare_v2(db, insertSql, -1, &stmt, nullptr) == SQLITE_OK) {
        sqlite3_bind_text(stmt, 1, title.c_str(), -1, SQLITE_STATIC);
        sqlite3_bind_text(stmt, 2, description.c_str(), -1, SQLITE_STATIC);
        sqlite3_bind_int64(stmt, 3, static_cast<sqlite3_int64>(date));
        if (sqlite3_step(stmt) != SQLITE_DONE) {
            std::cerr << "Gagal insert task" << std::endl;
        }
        sqlite3_finalize(stmt);
    } else {
        std::cerr << "Gagal menyiapkan statement insert" << std::endl;
    }

    sqlite3_close(db);
}