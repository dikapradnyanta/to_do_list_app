@echo off
setlocal enabledelayedexpansion

echo ========================================
echo SQLite Android FFI Builder
echo ========================================

:: Set NDK path yang benar
set ANDROID_NDK=C:\Users\Koman\AppData\Local\Android\Sdk\ndk\29.0.13599879

:: Verify NDK exists
if not exist "%ANDROID_NDK%" (
    echo ERROR: Android NDK not found at: %ANDROID_NDK%
    pause
    exit /b 1
)

echo Using NDK: %ANDROID_NDK%
echo.

:: Navigate to task directory
cd /d "C:\Users\Koman\Documents\PROJECT\Developer\Mobile Dev\to_do_list_app\android\app\src\main\cpp\task"

:: Check if SQLite files exist
echo Checking SQLite files...
if not exist "sqlite3.h" (
    echo.
    echo ==========================================
    echo SQLite files not found!
    echo ==========================================
    echo Please download SQLite amalgamation from:
    echo https://www.sqlite.org/download.html
    echo.
    echo 1. Look for "sqlite-amalgamation-xxx.zip"
    echo 2. Download and extract it
    echo 3. Copy sqlite3.h and sqlite3.c to this folder:
    echo    %CD%
    echo.
    pause
    exit /b 1
)

if not exist "sqlite3.c" (
    echo sqlite3.c not found! Please copy it to this folder.
    pause
    exit /b 1
)

echo SQLite files found ✓

:: Clean previous builds
echo Cleaning previous builds...
if exist "..\jniLibs" rmdir /s /q "..\jniLibs"

:: Create directories
mkdir "..\jniLibs\arm64-v8a" 2>nul
mkdir "..\jniLibs\armeabi-v7a" 2>nul

:: Build for ARM64
echo.
echo ==========================================
echo Building for ARM64...
echo ==========================================

"%ANDROID_NDK%\toolchains\llvm\prebuilt\windows-x86_64\bin\aarch64-linux-android21-clang++.cmd" ^
    -shared -fPIC ^
    -DSQLITE_THREADSAFE=1 ^
    -DSQLITE_ENABLE_FTS3 ^
    -DSQLITE_ENABLE_FTS3_PARENTHESIS ^
    -DSQLITE_ENABLE_RTREE ^
    -DSQLITE_ENABLE_JSON1 ^
    -O2 ^
    -o "..\jniLibs\arm64-v8a\libtask_ffi.so" ^
    task.cpp sqlite3.c

if !ERRORLEVEL! NEQ 0 (
    echo.
    echo ARM64 build FAILED! ❌
    echo Check the error messages above.
    pause
    exit /b 1
)

echo ARM64 build successful! ✓

:: Build for ARMv7
echo.
echo ==========================================
echo Building for ARMv7...
echo ==========================================

"%ANDROID_NDK%\toolchains\llvm\prebuilt\windows-x86_64\bin\armv7a-linux-androideabi21-clang++.cmd" ^
    -shared -fPIC ^
    -DSQLITE_THREADSAFE=1 ^
    -DSQLITE_ENABLE_FTS3 ^
    -DSQLITE_ENABLE_FTS3_PARENTHESIS ^
    -DSQLITE_ENABLE_RTREE ^
    -DSQLITE_ENABLE_JSON1 ^
    -O2 ^
    -o "..\jniLibs\armeabi-v7a\libtask_ffi.so" ^
    task.cpp sqlite3.c

if !ERRORLEVEL! NEQ 0 (
    echo.
    echo ARMv7 build FAILED! ❌
    echo Check the error messages above.
    pause
    exit /b 1
)

echo ARMv7 build successful! ✓

:: Show results
echo.
echo ==========================================
echo BUILD COMPLETED SUCCESSFULLY! 🎉
echo ==========================================
echo.
echo Libraries created:
echo - %CD%\..\jniLibs\arm64-v8a\libtask_ffi.so
echo - %CD%\..\jniLibs\armeabi-v7a\libtask_ffi.so
echo.

:: Check file sizes
for %%f in ("..\jniLibs\arm64-v8a\libtask_ffi.so") do (
    if exist "%%f" echo ARM64 size: %%~zf bytes
)
for %%f in ("..\jniLibs\armeabi-v7a\libtask_ffi.so") do (
    if exist "%%f" echo ARMv7 size: %%~zf bytes
)

echo.
echo You can now use these libraries in your Flutter app!
echo.
pause