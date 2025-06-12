cmake_minimum_required(VERSION 3.10.2)

project("task")

# Tambahkan library dari subfolder task/
add_library(
    task
    SHARED
    task/task.cpp
)

# Include direktori task/
include_directories(task)

# Temukan Android log library
find_library(
    log-lib
    log
)

# Link ke Android log (dan sqlite jika kamu perlukan nanti)
target_link_libraries(
    task
    ${log-lib}
)
