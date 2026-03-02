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

## System Architecture Highlights
*   **Antigravity Orchestration**: Central closed loop (`OBSERVE -> ANALYZE -> DECIDE -> EXECUTE -> LEARN -> RE-OPTIMIZE`) that manages 6 specialized agents.
*   **Behavioral Governor**: Applies friction mitigation (e.g. blocking sites, changing environment) rather than increasing notifications based on execution history.
*   **Mission Control UI**: Minimalist interface. No streaks, no gamification. Just executive briefings, strategic warnings, and single operational directions.
