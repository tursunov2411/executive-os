#!/bin/bash
# ================================================
# EXECUTIVE OS - macOS/Linux Full Stack Launcher
# ================================================
# Starts: Backend (FastAPI), Governor (skipped on macOS), Next.js Frontend
# Also opens the iOS companion in Xcode.
# ================================================

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo ""
echo " ============================================="
echo "  EXECUTIVE OS — INITIALIZING CONTROL STACK"
echo " ============================================="
echo ""

# Step 1: FastAPI Backend
echo "[1/3] Launching FastAPI Backend on port 8000..."
cd "$SCRIPT_DIR/backend"
source venv/bin/activate
uvicorn main:app --host 0.0.0.0 --port 8000 &
BACKEND_PID=$!
deactivate
sleep 2

# Step 2: Next.js Frontend
echo "[2/3] Launching Next.js Mission Control UI on port 3000..."
cd "$SCRIPT_DIR/frontend"
npm run dev &
FRONTEND_PID=$!

# Step 3: Open iOS Companion in Xcode (macOS only)
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "[3/3] Opening iOS Companion in Xcode..."
    XCODEPROJ=$(find "$SCRIPT_DIR/ios-companion" -name "*.xcodeproj" 2>/dev/null | head -n 1)
    if [ -n "$XCODEPROJ" ]; then
        open "$XCODEPROJ"
    else
        echo "       [!] No .xcodeproj found. Create the Xcode project manually from ios-companion/"
    fi
else
    echo "[3/3] Skipping iOS launch (macOS only)."
fi

echo ""
echo " ============================================="
echo "  EXECUTIVE OS STACK IS ONLINE"
echo " ============================================="
echo "  Backend API:     http://localhost:8000"
echo "  Mission Control: http://localhost:3000"
echo "  API Docs:        http://localhost:8000/docs"
echo "  Governor Daemon: Run separately as Admin (Windows only)"
echo " ============================================="
echo ""
echo "  Press CTRL+C to shut down all processes..."
echo ""

# Wait for any process to exit, then kill the rest
wait $BACKEND_PID $FRONTEND_PID
