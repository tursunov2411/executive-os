@echo off
:: ==============================================
:: Executive OS — One-Click Launch Script
:: RIGHT-CLICK → RUN AS ADMINISTRATOR
:: Launches: Backend, Frontend, Governor Daemon
:: ==============================================

:: Check for admin privileges (required for Governor)
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo  [!] This script requires Administrator privileges.
    echo  [!] Right-click launch_exec_os.bat and select "Run as administrator"
    echo.
    pause
    exit /b 1
)

:: Set project root to the folder containing this script
SET PROJECT_ROOT=%~dp0
CD /D %PROJECT_ROOT%

echo.
echo  ============================================
echo   EXECUTIVE OS — INITIALIZING CONTROL STACK
echo  ============================================
echo.

:: Step 1: FastAPI Backend
echo [1/3] Launching BackEnd (FastAPI) on port 8000...
START "EXEC-OS Backend" cmd /k "cd /d %PROJECT_ROOT%backend && .\venv\Scripts\activate && uvicorn main:app --host 0.0.0.0 --port 8000"

:: Brief pause so backend starts before frontend makes API calls
timeout /t 3 /nobreak >nul

:: Step 2: Next.js Frontend
echo [2/3] Launching Mission Control UI (Next.js) on port 3000...
START "EXEC-OS Frontend" cmd /k "cd /d %PROJECT_ROOT%frontend && npm run dev"

:: Step 3: Governor Daemon (requires admin — guaranteed by check above)
echo [3/3] Launching Behavioral Governor Daemon...
echo        SAFE_MODE is configured in governor\config.py
echo        Set SAFE_MODE=False to enable real OS enforcement.
START "EXEC-OS Governor" cmd /k "cd /d %PROJECT_ROOT%governor && .\venv\Scripts\activate && python main.py"

echo.
echo  ============================================
echo   EXECUTIVE OS IS LIVE
echo  ============================================
echo   Backend API:    http://localhost:8000
echo   API Docs:       http://localhost:8000/docs
echo   Mission Control: http://localhost:3000
echo.
echo   iOS Companion:  Open ios-companion\ in Xcode
echo                   Set baseURL in APIService.swift
echo                   to this PC's local IP + :8000
echo.
echo   Emergency Override: CTRL + ALT + ESC
echo  ============================================
echo.
pause
