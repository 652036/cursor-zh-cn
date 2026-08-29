@echo off
chcp 65001 >nul
cd /d "%~dp0"
echo 正在取消 Cursor 专用界面汉化（会先关闭 Cursor）...
py -3 --version >nul 2>&1
if not errorlevel 1 (
  py -3 "%~dp0cursor_zh.py" revert --kill --restart
  goto :done
)
python --version >nul 2>&1
if not errorlevel 1 (
  python "%~dp0cursor_zh.py" revert --kill --restart
  goto :done
)
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0CursorZh.ps1" revert
:done
echo.
pause
