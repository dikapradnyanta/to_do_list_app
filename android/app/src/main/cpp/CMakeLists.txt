cmake_minimum_required(VERSION 3.4.1)

add_library(
    task
    SHARED
    Task/task.cpp
    # tambahkan file lain jika perlu
)

find_library(
    log-lib
    log
)

target_link_libraries(
    task
    ${log-lib}
    sqlite3 # jika pakai sqlite
)