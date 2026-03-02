import SwiftUI
import SwiftData

/// Root tab bar with Pokedex and My Teams tabs.
struct MainTabView: View {
    @Environment(\.modelContext) private var context
    @State private var isLoadingPokemon = false
    @State private var loadError: String?

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
        .task {
            await loadPokemonDataIfNeeded()
        }
    }

    /// Downloads all 1025 Pokemon stubs on first launch (runs once, then cached)
    private func loadPokemonDataIfNeeded() async {
        do {
            isLoadingPokemon = true
            try await PokeAPIService.shared.loadAllPokemonStubs(context: context)
            isLoadingPokemon = false
        } catch {
            loadError = error.localizedDescription
            isLoadingPokemon = false
        }
    }
}
