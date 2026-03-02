import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'jsr:@supabase/supabase-js@2'

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization, X-Client-Info, Apikey",
}

interface AntigravityState {
  raw_input?: string
  parsed_actions?: any[]
  scored_actions?: any[]
  current_schedule?: any[]
  execution_logs?: any[]
  slipped_tasks?: any[]
  compliance_ema?: number
  tis_score?: number
  success_probability?: number
  current_cognitive_load?: number
}

const globalState: Map<string, AntigravityState> = new Map()

function getOrCreateState(userId: string): AntigravityState {
  if (!globalState.has(userId)) {
    globalState.set(userId, {
      slipped_tasks: [],
      execution_logs: [],
      compliance_ema: 0.85,
      tis_score: 0.0,
      success_probability: 0.0
    })
  }
  return globalState.get(userId)!
}

async function mockDecompose(goal: string): Promise<any[]> {
  return [
    { title: `Phase 1 of ${goal}`, level: "milestone", duration_mins: 120 },
    { title: `Phase 2 of ${goal}`, level: "milestone", duration_mins: 90 },
    { title: `Review ${goal}`, level: "atomic-action", duration_mins: 30 }
  ]
}

async function mockScoreActions(actions: any[]): Promise<any[]> {
  return actions.map(action => ({
    ...action,
    alignment_score: 0.85 + Math.random() * 0.15
  }))
}

async function mockSchedule(actions: any[]): Promise<any[]> {
  const now = new Date()
  return actions.map((action, idx) => ({
    ...action,
    id: `action-${idx}`,
    start_time: new Date(now.getTime() + idx * 60 * 60 * 1000).toISOString(),
    end_time: new Date(now.getTime() + (idx + 1) * 60 * 60 * 1000).toISOString()
  }))
}

function calculateTIS(compliance: number, avgAlignment: number, executionRatio: number): number {
  return compliance * avgAlignment * executionRatio
}

async function runCycle(userId: string, intent: string): Promise<AntigravityState> {
  const state = getOrCreateState(userId)

  state.raw_input = intent
  state.parsed_actions = await mockDecompose(intent)
  state.scored_actions = await mockScoreActions(state.parsed_actions)
  state.current_schedule = await mockSchedule(state.scored_actions)

  const executionLogs = state.execution_logs || []
  const completed = executionLogs.filter(log => log.status === "completed").length
  const executionRatio = executionLogs.length > 0 ? completed / executionLogs.length : 0.85

  state.compliance_ema = executionRatio
  state.tis_score = calculateTIS(executionRatio, 0.9, executionRatio)
  state.success_probability = Math.min(Math.max(state.tis_score, 0.0), 1.0)

  const totalLoad = state.current_schedule.reduce((sum, task) => {
    const duration_hrs = (task.duration_mins || 60) / 60.0
    return sum + (duration_hrs * 3)
  }, 0)
  state.current_cognitive_load = totalLoad

  return state
}

async function processExecutionFeedback(userId: string, feedback: any): Promise<AntigravityState> {
  const state = getOrCreateState(userId)

  if (!state.execution_logs) {
    state.execution_logs = []
  }

  state.execution_logs.push(feedback)

  const executionLogs = state.execution_logs
  const completed = executionLogs.filter(log => log.status === "completed").length
  const executionRatio = executionLogs.length > 0 ? completed / executionLogs.length : 0.85

  state.compliance_ema = executionRatio
  state.tis_score = calculateTIS(executionRatio, 0.9, executionRatio)
  state.success_probability = Math.min(Math.max(state.tis_score * 0.8, 0.0), 1.0)

  return state
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 200, headers: corsHeaders })
  }

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseKey = Deno.env.get('SUPABASE_ANON_KEY')!
    const supabase = createClient(supabaseUrl, supabaseKey)

    const authHeader = req.headers.get('Authorization')
    const { data: { user }, error: authError } = await supabase.auth.getUser(
      authHeader?.replace('Bearer ', '') || ''
    )

    if (authError || !user) {
      return new Response(
        JSON.stringify({ error: "Unauthorized" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      )
    }

    const url = new URL(req.url)
    const path = url.pathname

    if (path === "/" || path === "/executive-os-api" || path === "/executive-os-api/") {
      return new Response(
        JSON.stringify({ message: "Executive OS API is running. Awaiting input." }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } }
      )
    }

    if (path.endsWith("/api/cycle") && req.method === "POST") {
      const { intent } = await req.json()
      const state = await runCycle(user.id, intent)
      return new Response(
        JSON.stringify({ state }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } }
      )
    }

    if (path.endsWith("/api/state") && req.method === "GET") {
      const state = getOrCreateState(user.id)

      const execution_logs = state.execution_logs || []
      let recent_avoidance = false

      for (const log of execution_logs.slice(-3)) {
        if (log.status === "abandoned") {
          recent_avoidance = true
          break
        }
      }

      const responseState = {
        ...state,
        enforcement_packet: recent_avoidance ? {
          mode: "COMPENSATION_MODE",
          blocked_domains: ["youtube.com", "twitter.com", "reddit.com", "instagram.com"],
          blocked_apps: ["Discord.exe", "Spotify.exe", "Slack.exe", "msedge.exe"]
        } : null
      }

      return new Response(
        JSON.stringify({ state: responseState }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } }
      )
    }

    if (path.endsWith("/execution-log") && req.method === "POST") {
      const feedback = await req.json()
      const state = await processExecutionFeedback(user.id, feedback)
      return new Response(
        JSON.stringify({ status: "success", state }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } }
      )
    }

    if (path.endsWith("/api/active-enforcement") && req.method === "GET") {
      const state = getOrCreateState(user.id)
      const execution_logs = state.execution_logs || []
      let recent_avoidance = false

      for (const log of execution_logs.slice(-3)) {
        if (log.status === "abandoned") {
          recent_avoidance = true
          break
        }
      }

      if (!recent_avoidance) {
        return new Response(
          JSON.stringify({}),
          { headers: { ...corsHeaders, "Content-Type": "application/json" } }
        )
      }

      const packet = {
        mode: "COMPENSATION_MODE",
        blocked_domains: ["youtube.com", "twitter.com", "reddit.com", "instagram.com"],
        blocked_apps: ["Discord.exe", "Spotify.exe", "Slack.exe", "msedge.exe"]
      }

      return new Response(
        JSON.stringify(packet),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } }
      )
    }

    if (path.endsWith("/api/current-day") && req.method === "GET") {
      const state = getOrCreateState(user.id)
      const current_action = state.current_schedule?.[0]

      const daily_objective = {
        objectiveTitle: state.raw_input || "Awaiting Objective Insertion",
        criticalTask: current_action?.title || "None",
        cognitiveLoad: state.current_cognitive_load || 0.0,
        TIS: state.tis_score || 0.0,
        nextDeepWorkBlock: new Date(Date.now() + 5 * 60 * 60 * 1000).toISOString()
      }

      return new Response(
        JSON.stringify(daily_objective),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } }
      )
    }

    if (path.endsWith("/api/micro-starts") && req.method === "GET") {
      const state = getOrCreateState(user.id)
      const slipped = state.slipped_tasks || []

      const tasks = slipped.map((task, idx) => ({
        taskID: `ms-${idx}`,
        title: task.title || "Unknown",
        durationMinutes: 15,
        priorityScore: 0.9
      }))

      return new Response(
        JSON.stringify({ tasks }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } }
      )
    }

    if (path.endsWith("/api/feedback") && req.method === "POST") {
      const { taskID, status, actualDurationMinutes } = await req.json()

      const log = {
        task_id: taskID,
        planned_duration: actualDurationMinutes,
        actual_duration: actualDurationMinutes,
        status: status,
        friction_level: 5
      }

      const state = await processExecutionFeedback(user.id, log)

      return new Response(
        JSON.stringify({ status: "success", message: "Feedback ingested into Antigravity loop" }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } }
      )
    }

    return new Response(
      JSON.stringify({ error: "Not found" }),
      { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    )

  } catch (error) {
    console.error("Error:", error)
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    )
  }
})
