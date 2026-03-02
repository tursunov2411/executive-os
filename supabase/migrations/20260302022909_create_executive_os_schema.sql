/*
  # Executive OS Database Schema

  1. New Tables
    - `user_intent_profiles`
      - `id` (uuid, primary key)
      - `user_id` (uuid, references auth.users)
      - `baseline_thresholds` (jsonb)
      - `overarching_objective` (text)
      - `objective_vector` (vector(1536))
      - `created_at` (timestamptz)
      
    - `strategic_goal_trees`
      - `id` (uuid, primary key)
      - `user_id` (uuid, references auth.users)
      - `parent_id` (uuid, nullable, self-reference)
      - `level` (text) - 'macro-goal', 'milestone', 'mission', 'atomic-action'
      - `title` (text)
      - `description` (text)
      - `status` (text, default 'pending')
      - `priority_score` (float, default 1.0)
      - `created_at` (timestamptz)
      
    - `execution_history_logs`
      - `id` (uuid, primary key)
      - `user_id` (uuid, references auth.users)
      - `action_id` (uuid, references strategic_goal_trees)
      - `start_time` (timestamptz)
      - `end_time` (timestamptz, nullable)
      - `duration_minutes` (integer, default 0)
      - `completion_state` (text) - 'completed', 'slipped', 'aborted'
      - `friction_detected` (boolean, default false)
      - `created_at` (timestamptz)
      
    - `behavioral_pattern_models`
      - `id` (uuid, primary key)
      - `user_id` (uuid, references auth.users)
      - `pattern_description` (text)
      - `pattern_embedding` (vector(1536))
      - `resistance_score` (float, default 0.0)
      - `created_at` (timestamptz)
      
    - `time_allocation_maps`
      - `id` (uuid, primary key)
      - `user_id` (uuid, references auth.users)
      - `start_time` (timestamptz)
      - `end_time` (timestamptz)
      - `assigned_action_id` (uuid, references strategic_goal_trees)
      - `malleability_score` (float, default 1.0)
      - `state` (text, default 'scheduled')
      - `created_at` (timestamptz)
      
    - `compliance_scores`
      - `id` (uuid, primary key)
      - `user_id` (uuid, references auth.users)
      - `timestamp` (timestamptz)
      - `ema_score` (float)
      - `created_at` (timestamptz)
      
    - `adaptive_constraints`
      - `id` (uuid, primary key)
      - `user_id` (uuid, references auth.users)
      - `parameter_name` (text)
      - `parameter_value` (float)
      - `last_updated` (timestamptz)
      
  2. Security
    - Enable RLS on all tables
    - Add policies for authenticated users to manage their own data
*/

-- Enable pgvector extension
CREATE EXTENSION IF NOT EXISTS vector;

-- User Intent Profiles
CREATE TABLE IF NOT EXISTS user_intent_profiles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users NOT NULL,
  baseline_thresholds jsonb DEFAULT '{}'::jsonb,
  overarching_objective text,
  objective_vector vector(1536),
  created_at timestamptz DEFAULT now()
);

ALTER TABLE user_intent_profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own intent profiles"
  ON user_intent_profiles
  FOR ALL
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Strategic Goal Trees
CREATE TABLE IF NOT EXISTS strategic_goal_trees (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users NOT NULL,
  parent_id uuid REFERENCES strategic_goal_trees(id),
  level text NOT NULL,
  title text NOT NULL,
  description text,
  status text DEFAULT 'pending',
  priority_score float DEFAULT 1.0,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE strategic_goal_trees ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own goals"
  ON strategic_goal_trees
  FOR ALL
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Execution History Logs
CREATE TABLE IF NOT EXISTS execution_history_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users NOT NULL,
  action_id uuid REFERENCES strategic_goal_trees(id),
  start_time timestamptz NOT NULL,
  end_time timestamptz,
  duration_minutes integer DEFAULT 0,
  completion_state text NOT NULL,
  friction_detected boolean DEFAULT false,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE execution_history_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own execution logs"
  ON execution_history_logs
  FOR ALL
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Behavioral Pattern Models
CREATE TABLE IF NOT EXISTS behavioral_pattern_models (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users NOT NULL,
  pattern_description text NOT NULL,
  pattern_embedding vector(1536),
  resistance_score float DEFAULT 0.0,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE behavioral_pattern_models ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own behavioral patterns"
  ON behavioral_pattern_models
  FOR ALL
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Time Allocation Maps
CREATE TABLE IF NOT EXISTS time_allocation_maps (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users NOT NULL,
  start_time timestamptz NOT NULL,
  end_time timestamptz NOT NULL,
  assigned_action_id uuid REFERENCES strategic_goal_trees(id),
  malleability_score float DEFAULT 1.0,
  state text DEFAULT 'scheduled',
  created_at timestamptz DEFAULT now()
);

ALTER TABLE time_allocation_maps ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own time allocations"
  ON time_allocation_maps
  FOR ALL
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Compliance Scores
CREATE TABLE IF NOT EXISTS compliance_scores (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users NOT NULL,
  timestamp timestamptz DEFAULT now(),
  ema_score float NOT NULL,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE compliance_scores ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own compliance scores"
  ON compliance_scores
  FOR ALL
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Adaptive Constraints
CREATE TABLE IF NOT EXISTS adaptive_constraints (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users NOT NULL,
  parameter_name text NOT NULL,
  parameter_value float NOT NULL,
  last_updated timestamptz DEFAULT now()
);

ALTER TABLE adaptive_constraints ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own adaptive constraints"
  ON adaptive_constraints
  FOR ALL
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_goal_trees_user_id ON strategic_goal_trees(user_id);
CREATE INDEX IF NOT EXISTS idx_goal_trees_parent_id ON strategic_goal_trees(parent_id);
CREATE INDEX IF NOT EXISTS idx_execution_logs_user_id ON execution_history_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_execution_logs_action_id ON execution_history_logs(action_id);
CREATE INDEX IF NOT EXISTS idx_time_allocations_user_id ON time_allocation_maps(user_id);
CREATE INDEX IF NOT EXISTS idx_compliance_scores_user_id ON compliance_scores(user_id);
