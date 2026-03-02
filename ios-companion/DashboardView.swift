import SwiftUI

struct DashboardView: View {
    @StateObject private var apiService = APIService()
    @State private var timer: Timer?
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                Color.black.edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        
                        // Header
                        VStack(alignment: .leading, spacing: 4) {
                            Text("SYSTEM STATUS: ACTIVE")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(.gray)
                            Text("EXECUTIVE OS")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                        }
                        
                        Divider().background(Color.gray.opacity(0.3))
                        
                        // Current Direction Panel
                        if let obj = apiService.dailyObjective {
                            DirectionPanelView(objective: obj)
                        } else {
                            Text("Awaiting strategic objective insertion...")
                                .foregroundColor(.gray)
                                .italic()
                        }
                        
                        // Micro-Starts Queue
                        if !apiService.microStarts.isEmpty {
                            MicroStartsView(tasks: apiService.microStarts, apiService: apiService)
                        }
                    }
                    .padding()
                }
                
                // Enforcement Overlay Banner
                if let enforcement = apiService.activeEnforcement {
                    EnforcementBanner(enforcement: enforcement)
                        .transition(.move(edge: .bottom))
                        .animation(.easeInOut, value: apiService.activeEnforcement != nil)
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            // Initial fetch
            apiService.fetchDashboardData()
            
            // Poll every 5 seconds for MVP 
            self.timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
                apiService.fetchDashboardData()
            }
        }
        .onDisappear {
            self.timer?.invalidate()
        }
    }
}

// Subviews

struct DirectionPanelView: View {
    let objective: DailyObjective
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("CURRENT OPERATIONAL DIRECTION")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(.gray)
            
            Text(objective.criticalTask != "None" ? objective.criticalTask : objective.objectiveTitle)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
            
            HStack(spacing: 24) {
                VStack(alignment: .leading) {
                    Text("TIS SCORE")
                         .font(.system(size: 10, weight: .bold, design: .monospaced))
                         .foregroundColor(.gray)
                    Text("\(String(format: "%.1f", objective.TIS * 100))%")
                         .font(.system(size: 20, weight: .bold, design: .monospaced))
                         .foregroundColor(.white)
                }
                
                VStack(alignment: .leading) {
                    Text("COGNITIVE LOAD")
                         .font(.system(size: 10, weight: .bold, design: .monospaced))
                         .foregroundColor(.gray)
                    Text("\(String(format: "%.1f", objective.cognitiveLoad)) pts")
                         .font(.system(size: 20, weight: .bold, design: .monospaced))
                         .foregroundColor(.white)
                }
            }
        }
        .padding()
        .background(Color(white: 0.1))
        .cornerRadius(8)
        .overlay(
            Rectangle()
                .frame(width: 4)
                .foregroundColor(Color.orange)
                .padding(.leading, -2), // Slight offset
            alignment: .leading
        )
    }
}

struct MicroStartsView: View {
    let tasks: [MicroStartTask]
    let apiService: APIService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("MICRO-START QUEUE / FRICTION MITIGATED")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(.red)
            
            ForEach(tasks) { task in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(task.title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        Text("\(task.durationMinutes) MIN • TIS PROTECTED")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    
                    Button(action: {
                        // Mark as completed from mobile
                        apiService.sendFeedback(taskID: task.taskID, status: "completed", duration: task.durationMinutes)
                    }) {
                        Text("EXECUTE")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.white)
                            .cornerRadius(4)
                    }
                }
                .padding()
                .background(Color(white: 0.1))
                .cornerRadius(4)
            }
        }
    }
}

struct EnforcementBanner: View {
    let enforcement: EnforcementAlert
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Circle()
                    .fill(Color.red)
                    .frame(width: 10, height: 10)
                Text("ENVIRONMENT STATE: \(enforcement.mode ?? "LOCKED")")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                Spacer()
            }
            if let domains = enforcement.blocked_domains {
                HStack {
                     Text("Blocked Domains: \(domains.count)")
                        .font(.system(size: 12))
                        .foregroundColor(.red)
                     Spacer()
                }
            }
        }
        .padding()
        .background(Color(red: 0.3, green: 0, blue: 0))
        .border(Color.red, width: 2)
    }
}
