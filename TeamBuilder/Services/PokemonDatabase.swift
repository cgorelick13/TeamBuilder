import Foundation
import SwiftData

/// Seeds SwiftData with all 1025 Pokemon from the bundled pokemon_data.json file.
/// Call once on launch — skips automatically if already seeded.
struct PokemonDatabase {

    // MARK: - JSON entry shape (mirrors the Python script output)

    private struct PokemonEntry: Decodable {
        let id: Int
        let name: String
        let types: [String]
        let hp: Int
        let attack: Int
        let defense: Int
        let specialAttack: Int
        let specialDefense: Int
        let speed: Int
        let abilities: [String]
        let generation: Int
        let isLegendary: Bool
        let isMythical: Bool
        let evolutionChainIDs: [Int]
    }

    // MARK: - Sprite URL helpers (GitHub CDN — stable, no API call needed)

    private static func spriteURL(id: Int) -> String {
        "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/\(id).png"
    }

    private static func officialArtURL(id: Int) -> String {
        "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/\(id).png"
    }

    // MARK: - Seeding

    /// Seeds all Pokemon into the SwiftData model context from the bundled JSON file.
    /// Safe to call every launch — exits immediately if already seeded (>= 1025 records).
    static func seed(context: ModelContext) {
        // Check if already seeded
        let existing = (try? context.fetch(FetchDescriptor<CachedPokemon>())) ?? []
        if existing.count >= 1025 { return }

        // Load bundled JSON
        guard let url = Bundle.main.url(forResource: "pokemon_data", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            print("PokemonDatabase: pokemon_data.json not found in bundle")
            return
        }

        let decoder = JSONDecoder()
        guard let entries = try? decoder.decode([PokemonEntry].self, from: data) else {
            print("PokemonDatabase: failed to decode pokemon_data.json")
            return
        }

        // Build a lookup of existing records so we don't create duplicates
        var existingByID: [Int: CachedPokemon] = [:]
        for cached in existing { existingByID[cached.id] = cached }

        // Insert or update each entry
        for entry in entries {
            let pokemon: CachedPokemon
            if let existing = existingByID[entry.id] {
                pokemon = existing
            } else {
                pokemon = CachedPokemon(id: entry.id, name: entry.name)
                context.insert(pokemon)
            }

            // Populate all fields
            pokemon.name = entry.name
            pokemon.displayName = entry.name.capitalized.replacingOccurrences(of: "-", with: " ")
            pokemon.types = entry.types
            pokemon.hp = entry.hp
            pokemon.attack = entry.attack
            pokemon.defense = entry.defense
            pokemon.specialAttack = entry.specialAttack
            pokemon.specialDefense = entry.specialDefense
            pokemon.speed = entry.speed
            pokemon.abilities = entry.abilities
            pokemon.generation = entry.generation
            pokemon.isLegendary = entry.isLegendary
            pokemon.isMythical = entry.isMythical
            pokemon.evolutionChainIDs = entry.evolutionChainIDs
            pokemon.spriteURL = spriteURL(id: entry.id)
            pokemon.officialArtURL = officialArtURL(id: entry.id)
            pokemon.isFullyLoaded = true
        }

        try? context.save()
        print("PokemonDatabase: seeded \(entries.count) Pokemon")
    }
}
