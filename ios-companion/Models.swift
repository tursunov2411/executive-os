import Foundation

/// Data Models for Executive OS Companion App

struct DailyObjective: Codable {
    let objectiveTitle: String
    let criticalTask: String
    let cognitiveLoad: Double
    let TIS: Double
    let nextDeepWorkBlock: String // Using String for MVP simplicity (ISO8601)
}

struct MicroStartTask: Codable, Identifiable {
    var id: String { taskID }
    let taskID: String
    let title: String
    let durationMinutes: Int
    let priorityScore: Double
}

struct MicroStartsResponse: Codable {
    let tasks: [MicroStartTask]
}

struct EnforcementAlert: Codable {
    let mode: String?
    let blocked_domains: [String]?
    let blocked_apps: [String]?
}

struct ExecutionFeedback: Codable {
    let taskID: String
    let status: String // "completed", "partial", "abandoned"
    let actualDurationMinutes: Int
}
