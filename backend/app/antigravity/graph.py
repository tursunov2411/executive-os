from typing import Dict, Any
from app.antigravity.agents import (
    IntentAgent, StrategyAgent, SchedulerAgent, 
    BehavioralGovernorAgent, AnalyticsAgent, AdaptationAgent
)

class AntigravityOrchestrator:
    """
    Antigravity runtime orchestrator controlling all decision flows.
    Executes the closed-loop: OBSERVE -> ANALYZE -> DECIDE -> EXECUTE -> LEARN -> RE-OPTIMIZE
    """
    
    def __init__(self):
        self.state: Dict[str, Any] = {
            "slipped_tasks": []
        }
        
    async def run_cycle(self, raw_input: str) -> Dict[str, Any]:
        """Runs the complete cognitive loop"""
        
        # 1. OBSERVE (Intent)
        self.state["raw_input"] = raw_input
        self.state = await IntentAgent.process(self.state)
        
        # 2. ANALYZE (Strategy & Analytics)
        self.state = await StrategyAgent.process(self.state)
        self.state = await AnalyticsAgent.process(self.state)
        
        # 3. DECIDE (Scheduler)
        self.state = await SchedulerAgent.process(self.state)
        
        # 4. EXECUTE (Governor enforces environment constraints)
        self.state = await BehavioralGovernorAgent.process(self.state)
        
        # 5. LEARN & RE-OPTIMIZE (Adaptation)
        self.state = await AdaptationAgent.process(self.state)
        
        return self.state

    async def process_execution_feedback(self, feedback: Dict[str, Any]) -> Dict[str, Any]:
        """
        Receives real execution truth from the POST /execution-log endpoint.
        Immediately triggers the Adaptation Agent to reconsider future state.
        """
        if "execution_logs" not in self.state:
            self.state["execution_logs"] = []
            
        self.state["execution_logs"].append(feedback)
        print(f"[Orchestrator] Execution feedback logged: {feedback['task_id']} ({feedback['status']})")
        
        # Trigger the Adaptation phase immediately based on new truth
        self.state = await AdaptationAgent.process(self.state)
        return self.state

    async def process_daily_replan(self) -> Dict[str, Any]:
        """
        The background Daily Re-Optimization trigger that completely rewrites the 
        upcoming schedule based on the accumulated execution truth.
        """
        print("\n[Orchestrator] TRIGGERING BEHAVIORAL RE-PLAN...")
        # 1. Analyze (Strategy & Analytics)
        self.state = await StrategyAgent.process(self.state)
        self.state = await AnalyticsAgent.process(self.state)
        
        # 2. Re-allocate (Scheduler)
        self.state = await SchedulerAgent.process(self.state)
        
        return self.state
