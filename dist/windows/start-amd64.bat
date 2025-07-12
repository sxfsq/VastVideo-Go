@echo off
chcp 65001 >nul
REM VastVideo-Go Windows AMD64 专用启动脚本

REM 获取脚本所在目录
set SCRIPT_DIR=%~dp0

REM 切换到脚本目录
cd /d "%SCRIPT_DIR%"

REM 检查可执行文件是否存在
if not exist "VastVideo-Go-windows-amd64.exe" (
    echo 错误: 找不到 VastVideo-Go-windows-amd64.exe 可执行文件
    pause
    exit /b 1
)

REM 启动程序
echo 启动 VastVideo-Go (Windows AMD64)...
VastVideo-Go-windows-amd64.exe %*
pause
