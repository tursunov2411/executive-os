# Executive OS - Supabase Setup Guide

Your personal executive operating system is now running on Supabase.

## What's Been Deployed

### Database (Supabase PostgreSQL)
- User intent profiles with vector embeddings
- Strategic goal trees with hierarchical task structure
- Execution history logs for behavioral tracking
- Behavioral pattern models
- Time allocation maps
- Compliance scores and adaptive constraints
- Row Level Security enabled on all tables

### Backend (Supabase Edge Function)
- `executive-os-api` Edge Function deployed
- Handles all API endpoints:
  - `/api/cycle` - Process new strategic objectives
  - `/api/state` - Get current system state
  - `/api/active-enforcement` - Behavioral governor status
  - `/api/current-day` - Daily dashboard data
  - `/api/micro-starts` - Friction-mitigated task queue
  - `/api/feedback` - Execution feedback loop
  - `/execution-log` - Historical execution tracking

### Frontend (Next.js)
- Connected to Supabase authentication
- Integrated with Edge Function API
- Real-time dashboard with:
  - Current operational direction
  - Strategic warnings
  - Trajectory Integrity Score (TIS)
  - Behavioral enforcement status

## Quick Start

### 1. Install Dependencies
```bash
cd frontend
npm install
```

### 2. Environment Setup
The `.env.local` file has been created with your Supabase credentials.

### 3. Run Development Server
```bash
npm run dev
```

Open http://localhost:3000

### 4. Sign Up / Sign In
- Create an account on the login screen
- Check your email for confirmation (if email confirmation is enabled)
- Sign in to access your Executive OS dashboard

## How It Works

### 1. Strategic Objective Input
Enter your 12-month objective in the dashboard input field. The system will:
- Decompose it into executable milestones
- Assign alignment scores
- Create an adaptive schedule
- Calculate cognitive load

### 2. Execution Tracking
As you complete tasks, the system:
- Tracks actual vs planned duration
- Detects friction patterns
- Adjusts future allocations
- Protects trajectory integrity

### 3. Behavioral Governor
When resistance is detected:
- Environment locks activate
- Micro-starts are created (lower activation energy)
- Success-momentum tasks are prioritized
- Real-time adaptation occurs

### 4. Metrics
- **TIS (Trajectory Integrity Score)**: Compliance × Alignment × Execution
- **Cognitive Load**: Daily sustainable work capacity (max 25 pts)
- **Success Probability**: 12-month objective achievement forecast

## Architecture

```
User Input → Edge Function → Database
     ↓            ↓              ↓
  Dashboard ← API Response ← Row Level Security
```

## Security

- Authentication required for all API calls
- Row Level Security ensures users only access their data
- JWT tokens automatically managed by Supabase
- Environment variables secured in Supabase

## Next Steps

1. Enter your first strategic objective
2. Track execution for a few days
3. Observe adaptive scheduling behavior
4. Review TIS score and success probability
5. Let the system optimize your workflow

## Optional: Windows Governor Daemon

The Windows behavioral enforcement daemon can run locally to:
- Block distracting websites during deep work
- Terminate non-compliant applications
- Enable focus mode automatically

See `governor/` directory for setup instructions.

## iOS Companion App

The iOS app can be configured to connect to your Supabase backend:
1. Open `ios-companion/APIService.swift`
2. Update `baseURL` to: `https://tbevqcckwoqaudtumura.supabase.co/functions/v1/executive-os-api`
3. Build and run in Xcode

## Support

The system is designed to learn your behavioral patterns and adapt. Give it at least 7-14 days of execution data for optimal performance.
