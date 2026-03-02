import SwiftUI
import SwiftData

/// Root tab bar with Pokedex and My Teams tabs.
struct MainTabView: View {
    @Environment(\.modelContext) private var context

    var body: some View {
        TabView {
            PokedexView()
                .tabItem {
                    Label("Pokedex", systemImage: "square.grid.2x2.fill")
                }

            MyTeamsView()
                .tabItem {
                    Label("My Teams", systemImage: "person.3.fill")
                }
        }
        .onAppear {
            // Seeds all 1025 Pokemon from bundled JSON on first launch (instant after that)
            PokemonDatabase.seed(context: context)
        }
    }
}
