@echo off
chcp 65001 >nul
REM VastVideo-Go Windows 智能启动脚本

REM 获取脚本所在目录
set SCRIPT_DIR=%~dp0

REM 切换到脚本目录
cd /d "%SCRIPT_DIR%"

REM 检测系统架构
for /f "tokens=*" %%i in ('wmic os get osarchitecture /value ^| find "="') do set %%i
set ARCH=%osarchitecture%

REM 根据架构选择可执行文件
if "%ARCH%"=="32-bit" (
    set EXECUTABLE=VastVideo-Go-windows-386.exe
    echo 检测到 32 位系统，使用 386 版本
) else (
    set EXECUTABLE=VastVideo-Go-windows-amd64.exe
    echo 检测到 64 位系统，使用 AMD64 版本
)

REM 检查可执行文件是否存在
if not exist "%EXECUTABLE%" (
    echo 错误: 找不到 %EXECUTABLE% 可执行文件
    echo.
    echo 可用的可执行文件:
    if exist "VastVideo-Go-windows-amd64.exe" echo - VastVideo-Go-windows-amd64.exe
    if exist "VastVideo-Go-windows-386.exe" echo - VastVideo-Go-windows-386.exe
    echo.
    pause
    exit /b 1
)

REM 启动程序
echo 启动 VastVideo-Go (Windows %ARCH%)...
echo 使用可执行文件: %EXECUTABLE%
echo.
%EXECUTABLE% %*
pause
