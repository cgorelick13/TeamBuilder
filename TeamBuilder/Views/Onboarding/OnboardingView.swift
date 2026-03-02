import SwiftUI

/// 3-step swipeable intro shown on first launch. Calls onComplete when done.
struct OnboardingView: View {
    var onComplete: () -> Void
    @State private var page = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            systemImage: "square.grid.2x2.fill",
            title: "Browse Every Pokemon",
            description: "Search and filter all 1025 Pokemon across 9 generations. Find the perfect fit for your team."
        ),
        OnboardingPage(
            systemImage: "chart.bar.fill",
            title: "Understand Your Score",
            description: "Your team gets scored 0–100 based on type coverage, shared weaknesses, and stat roles. The higher the score, the more balanced your team."
        ),
        OnboardingPage(
            systemImage: "person.3.fill",
            title: "Build Your Team",
            description: "Add up to 6 Pokemon, see what threats you face, and get suggestions to fill gaps. Let's go!"
        )
    ]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                ForEach(pages.indices, id: \.self) { index in
                    OnboardingPageView(page: pages[index])
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .animation(.easeInOut, value: page)

            VStack(spacing: 12) {
                if page == pages.count - 1 {
                    Button("Get Started") { onComplete() }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                } else {
                    Button("Next") { withAnimation { page += 1 } }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                }

                Button("Skip") { onComplete() }
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
        }
        .background(Color(.systemBackground))
    }
}

private struct OnboardingPage {
    let systemImage: String
    let title: String
    let description: String
}

private struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: page.systemImage)
                .font(.system(size: 80))
                .foregroundStyle(.blue)
            Text(page.title)
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)
            Text(page.description)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
            Spacer()
        }
    }
}
