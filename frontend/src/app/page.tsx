"use client";

import React, { useState, useEffect } from 'react';

export default function ExecutiveDashboard() {
  const [state, setState] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [intentInput, setIntentInput] = useState('');
  const [processing, setProcessing] = useState(false);

  useEffect(() => {
    fetchState();
  }, []);

  const fetchState = async () => {
    try {
      const res = await fetch('http://localhost:8000/api/state');
      const data = await res.json();
      setState(data.state);
    } catch (err) {
      console.error("Failed to fetch state:", err);
    } finally {
      setLoading(false);
    }
  };

  const submitIntent = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!intentInput.trim()) return;

    setProcessing(true);
    try {
      const res = await fetch('http://localhost:8000/api/cycle', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ intent: intentInput }),
      });
      const data = await res.json();
      setState(data.state);
      setIntentInput('');
    } catch (err) {
      console.error("Failed to submit intent:", err);
    } finally {
      setProcessing(false);
    }
  };

  if (loading) {
    return <div className="min-h-screen bg-black text-white p-8 flex items-center justify-center">INITIALIZING EXECUTIVE OS...</div>;
  }

  // Derived state for the UI
  const currentAction = state?.current_schedule?.[0];
  const compliance = state?.compliance_ema ? (state.compliance_ema * 100).toFixed(1) : "---";
  const successProb = state?.success_probability ? (state.success_probability * 100).toFixed(1) : "---";
  const slippedTasks = state?.slipped_tasks || [];
  const activeEnforcement = state?.enforcement_packet; // Assuming backend sends this, we need to stitch it

  return (
    <div className="min-h-screen bg-black text-white p-8 flex flex-col relative pb-24">
      <header className="mb-12 border-b border-[#333] pb-4 flex justify-between items-end flex-wrap gap-4">
        <div>
          <h1 className="text-sm tracking-widest text-[#888] uppercase mb-1">System Status: Active</h1>
          <h2 className="text-2xl font-semibold tracking-tight">EXECUTIVE OS</h2>
        </div>
        <div className="text-right">
          <p className="text-xs text-[#888] uppercase tracking-wider">Antigravity Runtime Loop</p>
          <div className="flex gap-2 text-xs mt-1 font-mono">
            <span className={processing ? "text-yellow-500 animate-pulse" : "text-green-500"}>OBSERVE</span>
            <span className={processing ? "text-yellow-500 animate-pulse delay-75" : "text-green-500"}>ANALYZE</span>
            <span className={processing ? "text-yellow-500 animate-pulse delay-150" : "text-green-500"}>DECIDE</span>
            <span className={processing ? "text-yellow-500 animate-pulse delay-200" : "text-green-500"}>EXECUTE</span>
          </div>
        </div>
      </header>

      <main className="grid grid-cols-1 md:grid-cols-3 gap-6 flex-grow">
        {/* OPERATIONAL DIRECTION */}
        <section className="col-span-1 md:col-span-2 panel flex flex-col justify-center border-l-4 border-l-[#ff4500]">
          <h3 className="text-xs uppercase text-[#888] tracking-widest mb-4">Current Operational Direction</h3>
          {currentAction ? (
            <>
              <h2 className="text-4xl font-bold leading-tight mb-2">
                {currentAction.title}
              </h2>
              <p className="text-lg text-[#ccc] mb-6">
                Time Block: {currentAction.duration_mins} mins
                {currentAction.switching_cost_reduction_applied && " • [Friction Mitigated]"}
              </p>
              <div className="flex gap-4">
                <button className="bg-white text-black px-6 py-3 text-sm font-semibold hover:bg-gray-200 transition-colors">
                  CONFIRM EXECUTION
                </button>
                <button className="border border-[#555] text-white px-6 py-3 text-sm font-semibold hover:bg-[#222] transition-colors">
                  ABORT (RECALCULATE)
                </button>
              </div>
            </>
          ) : (
            <p className="text-lg text-[#ccc] italic">Awaiting strategic objective insertion...</p>
          )}
        </section>

        {/* STRATEGIC WARNINGS */}
        <section className="col-span-1 panel border-t-4 border-t-[#ff003c] overflow-y-auto max-h-[300px]">
          <h3 className="text-xs uppercase text-[#888] tracking-widest mb-4">Strategic Warnings</h3>
          <ul className="space-y-4">
            {slippedTasks.length > 0 ? (
              slippedTasks.map((task: any, idx: number) => (
                <li key={idx} className="flex gap-3">
                  <span className="text-[#ff003c] mt-1">●</span>
                  <div>
                    <h4 className="text-sm font-medium">Friction Detected</h4>
                    <p className="text-xs text-[#888]">
                      Slippage on '{task.title}'.
                      {task.friction_mitigation && ` Governor applied: ${task.friction_mitigation}.`}
                    </p>
                  </div>
                </li>
              ))
            ) : (
              <li className="text-xs text-[#555] italic">No active warnings. Execution nominal.</li>
            )}
            {state?.success_probability !== undefined && state.success_probability < 0.6 && (
              <li className="flex gap-3">
                <span className="text-[#ff4500] mt-1">●</span>
                <div>
                  <h4 className="text-sm font-medium">Trajectory Deviation Alert</h4>
                  <p className="text-xs text-[#888]">12-month objective success probability has dropped to {successProb}%.</p>
                </div>
              </li>
            )}
          </ul>
        </section>

        {/* DAILY EXECUTIVE BRIEFING */}
        <section className="col-span-1 md:col-span-3 panel mt-2">
          <h3 className="text-xs uppercase text-[#888] tracking-widest mb-4">Daily Executive Briefing</h3>
          <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
            <div className="col-span-3">
              <p className="text-sm leading-relaxed text-[#bbb]">
                {state?.raw_input ?
                  `System currently optimizing for intent: "${state.raw_input}". The Antigravity scheduler has recalculated time blocks based on operational priority. Current objective success chance is projected at ${successProb}%.` :
                  "Good morning. The system is awaiting your strategic input for the period."
                }
              </p>

              <div className="mt-6 border-t border-[#333] pt-4">
                <form onSubmit={submitIntent} className="flex gap-3">
                  <input
                    type="text"
                    value={intentInput}
                    onChange={(e) => setIntentInput(e.target.value)}
                    placeholder="Provide new objective or register an update..."
                    className="flex-grow bg-[#111] border border-[#333] px-4 py-2 text-sm text-white focus:outline-none focus:border-[#ff4500]"
                    disabled={processing}
                  />
                  <button
                    type="submit"
                    disabled={processing}
                    className="bg-[#333] text-white px-6 py-2 text-sm font-medium hover:bg-[#444] disabled:opacity-50"
                  >
                    {processing ? 'COMPUTING...' : 'DISPATCH'}
                  </button>
                </form>
              </div>
            </div>
            <div className="col-span-1 border-l border-[#333] pl-6 flex flex-col justify-center">
              <p className="text-xs text-[#888] uppercase mb-1">Trajectory Integrity (TIS)</p>
              <div className="text-3xl font-mono text-white">{state?.tis_score !== undefined ? (state.tis_score * 100).toFixed(1) : compliance}%</div>
            </div>
          </div>
        </section>
      </main>

      {/* UI TRANSPARENCY LAYER: BEHAVIORAL GOVERNOR STATUS */}
      {activeEnforcement && activeEnforcement.mode && (
        <div className="fixed bottom-0 left-0 right-0 bg-red-900 border-t-2 border-red-500 p-4 z-50">
          <div className="max-w-7xl mx-auto flex justify-between items-center text-sm">
            <div className="flex items-center gap-4">
              <span className="animate-pulse bg-red-500 h-3 w-3 rounded-full"></span>
              <strong className="tracking-widest uppercase">ENVIRONMENT STATE: {activeEnforcement.mode}</strong>
            </div>
            <div className="flex gap-8 text-red-200">
              <span>Blocked Domains: {activeEnforcement.blocked_domains?.length || 0}</span>
              <span>Monitored Apps: {activeEnforcement.blocked_apps?.length || 0}</span>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
