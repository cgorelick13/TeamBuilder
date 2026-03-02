import SwiftUI
import SwiftData

@main
struct TeamBuilderApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .modelContainer(for: [CachedPokemon.self, PokemonTeam.self])
        }
    }
}
