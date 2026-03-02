import SwiftUI

@main
struct ExecutiveOSApp: App {
    var body: some Scene {
        WindowGroup {
            DashboardView()
                .preferredColorScheme(.dark) // Executive OS is exclusively dark mode
        }
    }
}
