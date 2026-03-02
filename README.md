# Executive OS

**Executive OS** is a behavioral operating layer that sits ABOVE your digital environment and continuously optimizes your actions toward a single strategic objective. It functions as a Chief of Staff, Strategic Planner, Behavioral Enforcer, Calendar Orchestrator, Performance Analyst, and Adaptive Decision Engine.

## Directory Structure
- `backend/`: FastAPI + PostgreSQL + PGVector + Antigravity Orchestration logic.
- `frontend/`: Next.js Mission Control dashboard.
- `scripts/`: Simulation logic.

## Prerequisites
- Node.js > 18.x
- Python > 3.10
- PostgreSQL with `pgvector` extension installed.

## Local Deployment Instructions

### 1. Database Setup
Ensure PostgreSQL is running locally and install the `pgvector` extension.
```sql
CREATE DATABASE executive_os;
\c executive_os
CREATE EXTENSION vector;
```

### 2. Backend (FastAPI)
```bash
cd backend
python -m venv venv

# Windows
venv\Scripts\activate

pip install -r requirements.txt

# Start the server
uvicorn main:app --reload
```
The API will run at `http://localhost:8000`.

### 3. Frontend (Next.js)
```bash
cd frontend
npm install
npm run dev
```
The dashboard will run at `http://localhost:3000`.

### 4. Run the 30-Day Simulation
```bash
cd scripts
python simulate_30_days.py
```

## Production deployment (one-command)

Automated deploy for **backend** (Railway), **frontend** (Vercel), and **iOS** `APIService.swift` URL updates:

**Prerequisites:** [Railway CLI](https://docs.railway.app/develop/cli), [Vercel CLI](https://vercel.com/docs/cli), Git.

```bash
npm install -g railway vercel
railway login
vercel login
```

**macOS / Linux (Git Bash):**
```bash
chmod +x deploy_exec_os.sh
./deploy_exec_os.sh
```

**Windows (PowerShell):**
```powershell
.\deploy_exec_os.ps1
```

**Options:**

| Flag / Env | Description |
|------------|-------------|
| `--skip-backend` / `SKIP_BACKEND=1` | Skip Railway deploy |
| `--skip-frontend` / `SKIP_FRONTEND=1` | Skip Vercel deploy |
| `--skip-ios` / `SKIP_IOS=1` | Do not update `APIService.swift` |
| `--commit` / `COMMIT_CHANGES=1` | Commit and push `.env.local` + iOS URL changes |
| `BACKEND_URL=https://...` | Override backend URL (e.g. when skipping deploy or using Render/Fly.io) |

To use **Render** or **Fly.io** instead of Railway, set `BACKEND_URL` to your live backend URL and run with `--skip-backend` (deploy backend via their dashboard or CLI separately).

---

## System Architecture Highlights
*   **Antigravity Orchestration**: Central closed loop (`OBSERVE -> ANALYZE -> DECIDE -> EXECUTE -> LEARN -> RE-OPTIMIZE`) that manages 6 specialized agents.
*   **Behavioral Governor**: Applies friction mitigation (e.g. blocking sites, changing environment) rather than increasing notifications based on execution history.
*   **Mission Control UI**: Minimalist interface. No streaks, no gamification. Just executive briefings, strategic warnings, and single operational directions.
