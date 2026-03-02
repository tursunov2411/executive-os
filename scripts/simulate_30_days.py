import asyncio
import sys
import os

# Add backend to path
sys.path.append(os.path.join(os.path.dirname(__file__), '..', 'backend'))

from app.antigravity.graph import AntigravityOrchestrator

async def main():
    print("==================================================")
    print(" EXECUTIVE OS: 30-DAY ACCELERATED SIMULATION RUN ")
    print("==================================================")
    
    orchestrator = AntigravityOrchestrator()
    
    print("\n[Day 1] Initializing 12-Month Objective...")
    print("User Intent: 'I want to transition into a Senior AI Engineering role while running a marathon.'\n")
    
    # Run first cycle
    state = await orchestrator.run_cycle("I want to transition into a Senior AI Engineering role while running a marathon.")
    
    print("\n[Day 7] End of week review. User reports truth back to the system.")
    
    # Simulating actual execution feedback from the user throughout the week
    feedback_logs = [
        # Planned 45, Actual 15 -> Resistance (-66% Delta)
        {"task_id": "Phase 1 of I want to transition into a Senior AI Engineering role while running a marathon.", "planned_duration": 120, "actual_duration": 40, "status": "abandoned", "friction_level": 8},
        {"task_id": "Phase 2 of I want to transition into a Senior AI Engineering role while running a marathon.", "planned_duration": 90, "actual_duration": 95, "status": "completed", "friction_level": 3},
        {"task_id": "Review I want to transition into a Senior AI Engineering role while running a marathon.", "planned_duration": 30, "actual_duration": 0, "status": "abandoned", "friction_level": 9}
    ]
    
    for log in feedback_logs:
        print(f"\n>> Sending Execution Result: {log['task_id'][:30]}... ({log['status']})")
        state = await orchestrator.process_execution_feedback(log)
    
    
    print("\n[Day 14] Scheduled System Replan...")
    state = await orchestrator.process_daily_replan()
    
    print("\n==================================================")
    print(" SIMULATION COMPLETE. ")
    print(f" Final Projected Success Probability: {state.get('success_probability', 0.0) * 100:.1f}%")
    print(f" Current TIS (Trajectory Integrity Score): {state.get('tis_score', 0.0) * 100:.1f}%")
    print("\n Resulting Adaptive Schedule:")
    for task in state.get('current_schedule', []):
         print(f"  - {task['title']} (Scheduled mins: {task.get('duration_mins')})")
    print("==================================================")

if __name__ == "__main__":
    asyncio.run(main())
