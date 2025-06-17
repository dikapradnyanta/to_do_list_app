cmake_minimum_required(VERSION 3.10)

project(task)

# Include paths
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/task)
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/sqlite)

# 1. Tambahkan SQLite sebagai static library (khusus file C)
add_library(sqlite3 STATIC
    sqlite/sqlite3.c
)

# 2. Tambahkan library utama (C++) kamu
add_library(task SHARED
    task/task.cpp
)

# 3. Set C++ standard untuk file C++
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# 4. Flag compile hanya untuk C++
target_compile_options(task PRIVATE
    $<$<COMPILE_LANGUAGE:CXX>:-std=c++17 -frtti -fexceptions>
    -O2
    -DSQLITE_THREADSAFE=1
    -DSQLITE_ENABLE_FTS3
    -DSQLITE_ENABLE_FTS3_PARENTHESIS
    -DSQLITE_ENABLE_JSON1
    -DSQLITE_ENABLE_RTREE
    -DSQLITE_ENABLE_EXPLAIN_COMMENTS
)

# 5. Link sqlite3 ke task
target_link_libraries(task
    sqlite3
    android
    log
)

# 6. (Opsional) Export semua simbol untuk FFI
set_target_properties(task PROPERTIES
    LINK_FLAGS "-Wl,--export-dynamic"
)
