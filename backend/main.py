from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from app.core.config import settings
from app.antigravity.graph import AntigravityOrchestrator

app = FastAPI(
    title="Executive OS",
    description="A closed-loop human optimization system and behavioral operating layer.",
    version="1.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

orchestrator = AntigravityOrchestrator()

class IntentRequest(BaseModel):
    intent: str

class ExecutionLogRequest(BaseModel):
    task_id: str
    planned_duration: int
    actual_duration: int
    status: str
    friction_level: int

@app.get("/")
async def root():
    return {"message": "Executive OS API is running. Awaiting input."}

@app.post("/execution-log")
async def log_execution(request: ExecutionLogRequest):
    """
    Feeds execution truth back into the Antigravity graph.
    Given what actually happened today, what must change now?
    """
    state_updates = await orchestrator.process_execution_feedback(request.dict())
    return {"status": "success", "state": state_updates}

@app.get("/api/active-enforcement")
async def get_active_enforcement():
    """
    Endpoint polled by the local Behavioral Governor Daemon.
    Returns the current environment constraints based on the active schedule.
    """
    state = orchestrator.state
    
    # In a full PROD build, we would look at the `current_schedule` 
    # to see if a Deep Work block is active right this second.
    # For MVP, we pass down friction mitigations if we detect recent avoidance.
    
    execution_logs = state.get("execution_logs", [])
    recent_avoidance = False
    
    for log in execution_logs[-3:]: # Check last 3 logs
        if log.get("status") == "abandoned":
            recent_avoidance = True
            break
            
    if not recent_avoidance:
        return {}
        
    packet = {
        "mode": "COMPENSATION_MODE",
        "blocked_domains": ["youtube.com", "twitter.com", "reddit.com", "instagram.com"],
        "blocked_apps": ["Discord.exe", "Spotify.exe", "Slack.exe", "msedge.exe"]
    }
    return packet

@app.post("/api/cycle")
async def run_cycle(request: IntentRequest):
    state = await orchestrator.run_cycle(request.intent)
    return {"state": state}

@app.get("/api/state")
async def get_state():
    state = orchestrator.state.copy()
    
    # Run the same logic as the Governor polling to get the UI view
    execution_logs = state.get("execution_logs", [])
    recent_avoidance = False
    
    for log in execution_logs[-3:]:
        if log.get("status") == "abandoned":
            recent_avoidance = True
            break
            
    if recent_avoidance:
        state["enforcement_packet"] = {
            "mode": "COMPENSATION_MODE",
            "blocked_domains": ["youtube.com", "twitter.com", "reddit.com", "instagram.com"],
            "blocked_apps": ["Discord.exe", "Spotify.exe", "Slack.exe", "msedge.exe"]
        }
    else:
        state["enforcement_packet"] = None
        
    return {"state": state}

# ---------------------------------------------------------
# iOS Companion App Endpoints (Phase 5)
# ---------------------------------------------------------

@app.get("/api/current-day")
async def get_current_day():
    """Returns today's mission blocks, TIS, and cognitive load for the iOS Dashboard."""
    state = orchestrator.state
    
    current_action = state.get("current_schedule", [])[0] if state.get("current_schedule") else None
    
    # Format matches the expected Swift struct 
    daily_objective = {
        "objectiveTitle": state.get("raw_input", "Awaiting Objective Insertion"),
        "criticalTask": current_action.get("title") if current_action else "None",
        "cognitiveLoad": state.get("cognitive_load_used", 0.0),
        "TIS": state.get("tis_score", 0.0),
        "nextDeepWorkBlock": "2026-03-02T13:00:00Z" # Mocked for MVP
    }
    return daily_objective

@app.get("/api/micro-starts")
async def get_micro_starts():
    """Returns a list of tasks flagged as Micro-Starts by the Adaptive Agent."""
    state = orchestrator.state
    
    slipped = state.get("slipped_tasks", [])
    
    tasks = []
    for idx, task in enumerate(slipped):
        tasks.append({
            "taskID": f"ms-{idx}",
            "title": task.get("title", "Unknown"),
            "durationMinutes": 15, # Hardcoded micro-start block length
            "priorityScore": 0.9
        })
        
    return {"tasks": tasks}

class iOSFeedbackRequest(BaseModel):
    taskID: str
    status: str
    actualDurationMinutes: int

@app.post("/api/feedback")
async def receive_ios_feedback(request: iOSFeedbackRequest):
    """Receives two-way execution feedback from the iOS application."""
    
    # Map iOS struct to Python Backend Execution Log Struct
    log = {
        "task_id": request.taskID,
        "planned_duration": request.actualDurationMinutes, 
        "actual_duration": request.actualDurationMinutes,
        "status": request.status,
        "friction_level": 5 # Assumed average if not provided by UI
    }
    
    state_updates = await orchestrator.process_execution_feedback(log)
    return {"status": "success", "message": "Feedback ingested into Antigravity loop"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
