from sqlalchemy import Column, Integer, String, Float, DateTime, ForeignKey, JSON, Boolean
from sqlalchemy.orm import declarative_base, relationship
from pgvector.sqlalchemy import Vector
import datetime

Base = declarative_base()

class UserIntentProfile(Base):
    __tablename__ = "user_intent_profiles"
    id = Column(Integer, primary_key=True, index=True)
    baseline_thresholds = Column(JSON) # Configurable baseline parameters
    overarching_objective = Column(String)
    objective_vector = Column(Vector(1536)) # pgvector embedding of the 12-month goal
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

class StrategicGoalTree(Base):
    __tablename__ = "strategic_goal_trees"
    id = Column(Integer, primary_key=True, index=True)
    parent_id = Column(Integer, ForeignKey("strategic_goal_trees.id"), nullable=True)
    level = Column(String) # 'macro-goal', 'milestone', 'mission', 'atomic-action'
    title = Column(String)
    description = Column(String)
    status = Column(String, default="pending")
    priority_score = Column(Float, default=1.0)
    children = relationship("StrategicGoalTree", backref="parent", remote_side=[id])

class ExecutionHistoryLog(Base):
    __tablename__ = "execution_history_logs"
    id = Column(Integer, primary_key=True, index=True)
    action_id = Column(Integer, ForeignKey("strategic_goal_trees.id"))
    start_time = Column(DateTime)
    end_time = Column(DateTime, nullable=True)
    duration_minutes = Column(Integer, default=0)
    completion_state = Column(String) # 'completed', 'slipped', 'aborted'
    friction_detected = Column(Boolean, default=False)
    
class BehavioralPatternModel(Base):
    __tablename__ = "behavioral_pattern_models"
    id = Column(Integer, primary_key=True, index=True)
    pattern_description = Column(String)
    pattern_embedding = Column(Vector(1536))
    resistance_score = Column(Float, default=0.0) # Evaluated resistance to tasks

class TimeAllocationMap(Base):
    __tablename__ = "time_allocation_maps"
    id = Column(Integer, primary_key=True, index=True)
    start_time = Column(DateTime)
    end_time = Column(DateTime)
    assigned_action_id = Column(Integer, ForeignKey("strategic_goal_trees.id"))
    malleability_score = Column(Float, default=1.0) # 1.0 = highly flexible, 0.0 = deep work (locked)
    state = Column(String, default="scheduled")

class ComplianceScore(Base):
    __tablename__ = "compliance_scores"
    id = Column(Integer, primary_key=True, index=True)
    timestamp = Column(DateTime, default=datetime.datetime.utcnow)
    ema_score = Column(Float) # Exponential moving average of scheduled vs executed

class AdaptiveConstraints(Base):
    __tablename__ = "adaptive_constraints"
    id = Column(Integer, primary_key=True, index=True)
    parameter_name = Column(String) # e.g. 'max_deep_work_duration'
    parameter_value = Column(Float)
    last_updated = Column(DateTime, default=datetime.datetime.utcnow)
