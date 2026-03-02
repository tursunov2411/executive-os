# Executive OS iOS Companion App (Phase 5)

This folder contains the complete SwiftUI codebase for the Executive OS Companion App.

## Prerequisites
1. **macOS** with a recent version of Xcode (15+).
2. The `executive-os/backend` FastAPI server must be running.

## Setup Instructions

1. **Create an Xcode Project:**
   Open Xcode -> File -> New -> Project -> "App" (iOS). Name it `ExecutiveOS`.

2. **Add Source Files:**
   Replace the default `ContentView.swift` and scaffolding with the files provided in this directory:
   - `Models.swift`: The Codable data structures holding daily objectives and warnings.
   - `APIService.swift`: The network layer that talks to the Antigravity Orchestrator on your PC.
   - `DashboardView.swift`: The main UI view (Mission Control) featuring the enforcement locks, slip mitigation queues, and execution reporting.
   - `ExecutiveOSApp.swift`: The `@main` entry point.

3. **Configure Network Access:**
   Ensure the `baseURL` inside `APIService.swift` points to the Local IP Address of your Windows PC hosting the FastAPI backend (e.g. `192.168.1.X:8000`).

4. **Build and Run:**
   Select your connected iPhone or a simulator and hit **Run (CMD+R)**!
