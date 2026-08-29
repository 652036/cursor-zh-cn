@echo off
chcp 65001 >nul
cd /d "%~dp0"
echo 正在汉化 Cursor（会先关闭 Cursor）...
py -3 --version >nul 2>&1
if not errorlevel 1 (
  py -3 "%~dp0cursor_zh.py" apply --kill --restart
  goto :done
)
python --version >nul 2>&1
if not errorlevel 1 (
  python "%~dp0cursor_zh.py" apply --kill --restart
  goto :done
)
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0CursorZh.ps1" apply
:done
echo.
pause
