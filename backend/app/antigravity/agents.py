from typing import Dict, Any
from app.core.algorithms import (
    GoalDecompositionEngine, 
    TimeRebalancingFunction, 
    AlignmentScoringModel, 
    FrictionOptimization, 
    TrajectoryForecasting,
    AdaptiveRescheduler,
    MetricsEngine
)

class IntentAgent:
    """Captures raw human goals from voice/text. Transforms into execution graphs."""
    @staticmethod
    async def process(state: Dict[str, Any]) -> Dict[str, Any]:
        raw_intent = state.get("raw_input", "")
        print(f"[Intent Agent] Parsing raw intent: '{raw_intent}'")
        parsed_actions = await GoalDecompositionEngine.decompose(raw_intent)
        state["parsed_actions"] = parsed_actions
        return state

class StrategyAgent:
    """Converts structured goals into long-horizon plans."""
    @staticmethod
    async def process(state: Dict[str, Any]) -> Dict[str, Any]:
        print("[Strategy Agent] Enforcing strategic coherence and building milestones.")
        actions = state.get("parsed_actions", [])
        # Assign objective vector and score each action
        objective_vector = [0.1] * 1536 # Mock vector
        scored_actions = []
        for action in actions:
            score = await AlignmentScoringModel.score_action(action["title"], objective_vector)
            action["alignment_score"] = score
            scored_actions.append(action)
        state["scored_actions"] = scored_actions
        return state

class SchedulerAgent:
    """Creates a FLUID calendar, detecting execution failure early."""
    @staticmethod
    async def process(state: Dict[str, Any]) -> Dict[str, Any]:
        print("[Scheduler Agent] Dynamically rebalancing workload and allocating blocks based on behavioral truth.")
        scored_actions = state.get("scored_actions", [])
        execution_logs = state.get("execution_logs", [])
        
        # Use the Phase 3 Adaptive Rescheduler
        schedule = await AdaptiveRescheduler.reallocate_time(scored_actions, execution_logs)
        state["current_schedule"] = schedule
        
        # Track cognitive load
        daily_load = AdaptiveRescheduler.calculate_cognitive_load(schedule)
        state["current_cognitive_load"] = daily_load
        print(f"  -> Projected Daily Cognitive Load: {daily_load:.1f}/25")
        
        return state

class BehavioralGovernorAgent:
    """Implements environment-level enforcement. Removes reliance on willpower."""
    @staticmethod
    async def process(state: Dict[str, Any]) -> Dict[str, Any]:
        print("[Behavioral Governor Agent] Adjusting system friction / focus modes.")
        slipped_tasks = state.get("slipped_tasks", [])
        for task in slipped_tasks:
            optimized_task = await FrictionOptimization.optimize_friction(task, slip_count=3) # Assume max slips
            print(f"  -> Applying mitigation: {optimized_task.get('friction_mitigation', 'none')} to {task.get('title')}")
        return state

class AnalyticsAgent:
    """Produces performance diagnostics and execution efficiency."""
    @staticmethod
    async def process(state: Dict[str, Any]) -> Dict[str, Any]:
        print("[Analytics Agent] Evaluating planned vs actual behavior.")
        
        execution_logs = state.get("execution_logs", [])
        if not execution_logs:
            state["compliance_ema"] = 0.85
            state["tis_score"] = 0.0
            return state
            
        # Calculate Mock execution metrics
        completed = sum(1 for log in execution_logs if log.get("status") == "completed")
        execution_ratio = completed / len(execution_logs) if execution_logs else 0.85
        
        state["compliance_ema"] = execution_ratio
        
        # Calculate Trajectory Integrity Score (TIS)
        # Assuming avg alignment is 0.9 for mock
        tis = MetricsEngine.calculate_tis(compliance=execution_ratio, avg_alignment=0.9, execution_ratio=execution_ratio)
        state["tis_score"] = tis
        print(f"  -> Current Trajectory Integrity Score (TIS): {tis*100:.1f}")
        
        return state

class AdaptationAgent:
    """Learns the user's behavioral signature to adjust workloads realism."""
    @staticmethod
    async def process(state: Dict[str, Any]) -> Dict[str, Any]:
        print("[Adaptation Agent] Predicting failure zones and adjusting workloads.")
        compliance = state.get("compliance_ema", 0.5)
        tis = state.get("tis_score", 0.0)
        
        # Forecast uses TIS logic if available
        base_metric = tis if tis > 0 else compliance
        
        prob = await TrajectoryForecasting.estimate_success_probability(base_metric, 365)
        print(f"  -> Projected 12-month Objective Success Probability: {prob*100:.1f}%")
        state["success_probability"] = prob
        return state
