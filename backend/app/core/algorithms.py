import random
import json
from datetime import datetime, timedelta
from typing import List, Dict, Any
from openai import AsyncOpenAI
from app.core.config import settings

# Mock LLM / Embeddings fallback for prototype
def mock_get_embedding(text: str) -> List[float]:
    return [random.uniform(-1, 1) for _ in range(1536)]

def cosine_similarity(v1: List[float], v2: List[float]) -> float:
    dot_product = sum(a * b for a, b in zip(v1, v2))
    norm_a = sum(a * a for a in v1) ** 0.5
    norm_b = sum(b * b for b in v2) ** 0.5
    if norm_a == 0 or norm_b == 0: return 0.0
    return dot_product / (norm_a * norm_b)

class GoalDecompositionEngine:
    @staticmethod
    async def decompose(macro_goal: str) -> List[Dict[str, Any]]:
        """
        Breaks macro-objectives into executable atomic actions using an LLM.
        Falls back to mock semantic decomposition if API key is invalid/missing.
        """
        try:
            if settings.OPENAI_API_KEY and settings.OPENAI_API_KEY != "your-openai-api-key":
                client = AsyncOpenAI(api_key=settings.OPENAI_API_KEY)
                response = await client.chat.completions.create(
                    model="gpt-3.5-turbo",
                    messages=[
                        {"role": "system", "content": "You are a behavioral decomposition engine. Break the user intent down into 3 minimal atomic actions. Each must take less than 2 hours. Return raw JSON array: [{'title': '...', 'level': 'atomic-action', 'duration_mins': 60}]."},
                        {"role": "user", "content": macro_goal}
                    ]
                )
                raw_json = response.choices[0].message.content
                return json.loads(raw_json)
        except Exception as e:
            print(f"LLM Error, falling back to mock rules. ({e})")
            
        return [
            {"title": f"Phase 1 of {macro_goal}", "level": "milestone", "duration_mins": 120},
            {"title": f"Phase 2 of {macro_goal}", "level": "milestone", "duration_mins": 90},
            {"title": f"Review {macro_goal}", "level": "atomic-action", "duration_mins": 30}
        ]

class TimeRebalancingFunction:
    @staticmethod
    async def recalculate_schedule(slipped_tasks: List[Dict], current_schedule: List[Dict]) -> List[Dict]:
        """
        When execution deviates, recalculate schedule using weighted priority redistribution.
        Low priority tasks get bumped out.
        """
        # Sort current schedule by priority score descending
        current_schedule.sort(key=lambda x: x.get('priority_score', 0), reverse=True)
        
        rebalanced = []
        current_time = datetime.utcnow()
        
        # Slipped tasks get immediate attention if high priority, or pushed if low
        all_tasks = slipped_tasks + current_schedule
        all_tasks.sort(key=lambda x: x.get('priority_score', 0) * x.get('malleability_score', 1.0), reverse=True)
        
        for task in all_tasks:
            rebalanced.append({
                **task,
                "start_time": current_time,
                "end_time": current_time + timedelta(minutes=task.get('duration_mins', 60))
            })
            current_time += timedelta(minutes=task.get('duration_mins', 60))
            
        return rebalanced

class AdaptiveRescheduler:
    @staticmethod
    def compute_execution_delta(planned: int, actual: int) -> float:
        """
        Calculates the reality gap of a task.
        Returns a negative percentage if skipped/short, positive if over time.
        """
        if planned == 0: return 0.0
        return (actual - planned) / planned

    @staticmethod
    def calculate_cognitive_load(schedule: List[Dict]) -> int:
        """
        Each day gets a max load score to prevent unrealistic plans.
        """
        # Dictionary of weights per task type
        load_weights = {
            "deep_work": 5, # points per hour
            "admin": 2,
            "reading": 3,
            "default": 3
        }
        
        total_load = 0
        for task in schedule:
            task_type = task.get("type", "default")
            duration_hrs = task.get("duration_mins", 60) / 60.0
            weight = load_weights.get(task_type, load_weights["default"])
            total_load += duration_hrs * weight
            
        return total_load
        
    @staticmethod
    async def reallocate_time(goal_tree: List[Dict], execution_logs: List[Dict]) -> List[Dict]:
        """
        The core of Phase 3.
        1. Reduce future allocation to repeatedly resisted tasks.
        2. Insert smaller entry points (lower activation energy).
        3. Protect momentum by shifting success-based tasks earlier.
        """
        
        # Analyze resistance from logs
        resistance_map = {}
        for log in execution_logs:
            task_id = log.get("task_id")
            delta = AdaptiveRescheduler.compute_execution_delta(log.get("planned_duration", 60), log.get("actual_duration", 60))
            
            if task_id not in resistance_map:
                resistance_map[task_id] = 0
                
            # Detect avoidance patterns
            if delta < -0.4 or log.get("status") == "abandoned":
                resistance_map[task_id] += 1
            elif delta >= 0.0 and log.get("status") == "completed":
                resistance_map[task_id] -= 1 # Building momentum
        
        reallocated_schedule = []
        MAX_DAILY_LOAD = 25 # Absolute limit for sustainable human output
        current_load = 0
        
        # Rebuild schedule based on behavioral economics
        for task in goal_tree:
            task_id = task.get("id", task.get("title"))
            resistance = resistance_map.get(task_id, 0)
            
            # Reduce activation energy for highly resisted tasks
            if resistance >= 2:
                task["duration_mins"] = max(15, task.get("duration_mins", 60) // 2)
                task["title"] = f"Micro-Start: {task['title']}"
            
            # Predict cognitive hit
            duration_hrs = task.get("duration_mins", 60) / 60.0
            load_cost = duration_hrs * 3 # Default weight
            
            if current_load + load_cost > MAX_DAILY_LOAD:
                # Budget exceeded, push to backlog
                task["status"] = "backlogged_due_to_load"
            else:
                current_load += load_cost
                reallocated_schedule.append(task)
                
        # Protect momentum: Sort so tasks with negative resistance (success momentum) happen earlier
        reallocated_schedule.sort(key=lambda x: resistance_map.get(x.get("id", x.get("title")), 0))
                
        return reallocated_schedule


class AlignmentScoringModel:
    @staticmethod
    async def score_action(action_description: str, objective_vector: List[float]) -> float:
        """
        Every action receives a strategic relevance score via cosine similarity.
        Low-scoring behaviors will be suppressed by the Governor.
        """
        action_vector = mock_get_embedding(action_description)
        return cosine_similarity(action_vector, objective_vector)

class MetricsEngine:
    @staticmethod
    def calculate_tis(compliance: float, avg_alignment: float, execution_ratio: float) -> float:
        """
        Calculates Trajectory Integrity Score (TIS).
        TIS = Consistency (Compliance) * Strategic Alignment * Execution Ratio
        """
        return compliance * avg_alignment * execution_ratio

class FrictionOptimization:
    @staticmethod
    async def optimize_friction(task: Dict, slip_count: int) -> Dict:
        """
        If user resists tasks (slip_count > threshold), reduce switching cost
        rather than increasing reminders.
        """
        if slip_count >= 3:
            # Action to take via Governor: e.g. "Auto-open required apps", "Block all other sites"
            task["switching_cost_reduction_applied"] = True
            task["friction_mitigation"] = "strict_environment_lock"
            task["duration_mins"] = max(15, task.get("duration_mins", 60) // 2) # Reduce perceived load
        return task

class TrajectoryForecasting:
    @staticmethod
    async def estimate_success_probability(compliance_ema: float, days_remaining: int) -> float:
        """
        Continuously estimate: “If behavior continues like this, what is the probability of success?”
        """
        # Simple probabilistic model based on compliance momentum
        base_probability = compliance_ema
        momentum_factor = 1.0 if days_remaining > 30 else 0.8
        
        projected = base_probability * momentum_factor
        return min(max(projected, 0.0), 1.0) # Clamp between 0 and 1
