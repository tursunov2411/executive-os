import Foundation
import Combine

class APIService: ObservableObject {
    @Published var dailyObjective: DailyObjective?
    @Published var microStarts: [MicroStartTask] = []
    @Published var activeEnforcement: EnforcementAlert?
    
    // Replace with your Windows PC's local IP address
    private let baseURL = "http://192.168.1.100:8000"
    
    func fetchDashboardData() {
        guard let url = URL(string: "\(baseURL)/api/current-day") else { return }
        URLSession.shared.dataTask(with: url) { data, _, _ in
            if let data = data, let decoded = try? JSONDecoder().decode(DailyObjective.self, from: data) {
                DispatchQueue.main.async { self.dailyObjective = decoded }
            }
        }.resume()
        
        fetchMicroStarts()
        fetchEnforcement()
    }
    
    func fetchMicroStarts() {
        guard let url = URL(string: "\(baseURL)/api/micro-starts") else { return }
        URLSession.shared.dataTask(with: url) { data, _, _ in
            if let data = data, let decoded = try? JSONDecoder().decode(MicroStartsResponse.self, from: data) {
                DispatchQueue.main.async { self.microStarts = decoded.tasks }
            }
        }.resume()
    }
    
    func fetchEnforcement() {
        guard let url = URL(string: "\(baseURL)/api/active-enforcement") else { return }
        URLSession.shared.dataTask(with: url) { data, response, _ in
            // Handle the empty dictionary {} response when no enforcement is active
            if let data = data, let decoded = try? JSONDecoder().decode(EnforcementAlert.self, from: data) {
                 DispatchQueue.main.async {
                     if decoded.mode != nil {
                         self.activeEnforcement = decoded
                     } else {
                         self.activeEnforcement = nil
                     }
                 }
            } else {
               DispatchQueue.main.async { self.activeEnforcement = nil }
            }
        }.resume()
    }
    
    func sendFeedback(taskID: String, status: String, duration: Int) {
        guard let url = URL(string: "\(baseURL)/api/feedback") else { return }
        
        let feedback = ExecutionFeedback(taskID: taskID, status: status, actualDurationMinutes: duration)
        guard let encoded = try? JSONEncoder().encode(feedback) else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = encoded
        
        URLSession.shared.dataTask(with: request) { _, _, _ in
            // After sending feedback, refresh the dashboard to get new adaptive schedule
            self.fetchDashboardData()
        }.resume()
    }
}
