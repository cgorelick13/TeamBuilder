import SwiftUI
import SwiftData

/// Entry point view — shows onboarding on first launch, then the main tab interface.
struct RootView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @Environment(\.modelContext) private var context

    // The currently "active" team ID (drives Pokedex overlays and suggestions)
    @AppStorage("activeTeamID") private var activeTeamIDString = ""

    var body: some View {
        if hasSeenOnboarding {
            MainTabView()
        } else {
            OnboardingView {
                hasSeenOnboarding = true
            }
        }
    }
}
