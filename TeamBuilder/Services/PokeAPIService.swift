import Foundation
import SwiftData

/// Fetches Pokemon data from PokeAPI and caches it in SwiftData.
/// All network calls use async/await.
actor PokeAPIService {

    static let shared = PokeAPIService()
    private let baseURL = "https://pokeapi.co/api/v2"

    // MARK: - Step 1: Load all Pokemon names (runs once on first launch)

    /// Fetches all 1025 Pokemon names and IDs and saves them as lightweight stubs.
    func loadAllPokemonStubs(context: ModelContext) async throws {
        // Check if we've already loaded stubs
        let existing = try context.fetch(FetchDescriptor<CachedPokemon>())
        if existing.count >= 1025 { return }

        // Fetch from API — limit 1025 covers all generations
        let url = URL(string: "\(baseURL)/pokemon?limit=1025&offset=0")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(PokemonListResponse.self, from: data)

        // Insert stubs into SwiftData
        for (index, result) in response.results.enumerated() {
            let id = index + 1
            // Skip if already cached
            let predicate = #Predicate<CachedPokemon> { $0.id == id }
            if let _ = try context.fetch(FetchDescriptor(predicate: predicate)).first { continue }
            let stub = CachedPokemon(id: id, name: result.name)
            context.insert(stub)
        }
        try context.save()
    }

    // MARK: - Step 2: Load full detail for a single Pokemon

    /// Fetches and caches full Pokemon data (types, stats, sprites, abilities).
    /// Safe to call multiple times — returns early if already fully loaded.
    func loadFullPokemon(id: Int, context: ModelContext) async throws -> CachedPokemon {
        // Return from cache if already fully loaded
        let predicate = #Predicate<CachedPokemon> { $0.id == id }
        if let cached = try context.fetch(FetchDescriptor(predicate: predicate)).first,
           cached.isFullyLoaded {
            return cached
        }

        // Fetch from API
        let url = URL(string: "\(baseURL)/pokemon/\(id)")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let detail = try JSONDecoder().decode(PokemonDetailResponse.self, from: data)

        // Also fetch species for legendary/mythical/generation info
        let speciesURL = URL(string: "\(baseURL)/pokemon-species/\(id)")!
        let (speciesData, _) = try await URLSession.shared.data(from: speciesURL)
        let species = try JSONDecoder().decode(PokemonSpeciesResponse.self, from: speciesData)

        // Fetch or create the cached record
        let pokemon: CachedPokemon
        if let existing = try context.fetch(FetchDescriptor(predicate: predicate)).first {
            pokemon = existing
        } else {
            pokemon = CachedPokemon(id: id, name: detail.name)
            context.insert(pokemon)
        }

        // Populate fields
        pokemon.name = detail.name
        pokemon.displayName = detail.name.capitalized.replacingOccurrences(of: "-", with: " ")
        pokemon.types = detail.types.sorted { $0.slot < $1.slot }.map { $0.type.name }
        pokemon.spriteURL = detail.sprites.frontDefault
        pokemon.officialArtURL = detail.sprites.other?.officialArtwork?.frontDefault

        // Stats
        for stat in detail.stats {
            switch stat.stat.name {
            case "hp":              pokemon.hp = stat.baseStat
            case "attack":          pokemon.attack = stat.baseStat
            case "defense":         pokemon.defense = stat.baseStat
            case "special-attack":  pokemon.specialAttack = stat.baseStat
            case "special-defense": pokemon.specialDefense = stat.baseStat
            case "speed":           pokemon.speed = stat.baseStat
            default: break
            }
        }

        // Abilities
        pokemon.abilities = detail.abilities.sorted { $0.slot < $1.slot }.map { $0.ability.name }

        // Species info
        pokemon.isLegendary = species.isLegendary
        pokemon.isMythical = species.isMythical
        pokemon.generation = generationNumber(from: species.generation.name)

        // Evolution chain (fetch asynchronously — non-blocking for display)
        if let chainURL = species.evolutionChain?.url {
            if let chainIDs = try? await fetchEvolutionChainIDs(from: chainURL) {
                pokemon.evolutionChainIDs = chainIDs
            }
        }

        pokemon.isFullyLoaded = true
        try context.save()
        return pokemon
    }

    // MARK: - Ability description

    /// Returns the plain-English description for an ability name
    func abilityDescription(name: String) async throws -> String {
        let url = URL(string: "\(baseURL)/ability/\(name)")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(AbilityResponse.self, from: data)
        // Prefer the most recent English short effect entry
        return response.effectEntries
            .filter { $0.language.name == "en" }
            .last?.shortEffect ?? "No description available."
    }

    // MARK: - Private helpers

    private func fetchEvolutionChainIDs(from urlString: String) async throws -> [Int] {
        let url = URL(string: urlString)!
        let (data, _) = try await URLSession.shared.data(from: url)
        let chain = try JSONDecoder().decode(EvolutionChainResponse.self, from: data)
        return extractIDs(from: chain.chain)
    }

    private func extractIDs(from link: ChainLink) -> [Int] {
        var ids: [Int] = []
        if let id = pokemonIDFromURL(link.species.url) { ids.append(id) }
        for next in link.evolvesTo { ids += extractIDs(from: next) }
        return ids
    }

    private func pokemonIDFromURL(_ url: String) -> Int? {
        // URL format: https://pokeapi.co/api/v2/pokemon-species/{id}/
        let parts = url.split(separator: "/")
        return Int(parts.last ?? "")
    }

    private func generationNumber(from name: String) -> Int {
        // name format: "generation-i", "generation-ii", etc.
        let map = ["i": 1, "ii": 2, "iii": 3, "iv": 4, "v": 5,
                   "vi": 6, "vii": 7, "viii": 8, "ix": 9]
        let suffix = name.replacingOccurrences(of: "generation-", with: "")
        return map[suffix] ?? 0
    }
}

// MARK: - API Response Models

private struct PokemonListResponse: Decodable {
    let results: [NamedResource]
}

private struct NamedResource: Decodable {
    let name: String
    let url: String
}

private struct PokemonDetailResponse: Decodable {
    let name: String
    let types: [TypeSlot]
    let stats: [StatEntry]
    let abilities: [AbilitySlot]
    let sprites: Sprites

    struct TypeSlot: Decodable {
        let slot: Int
        let type: NamedResource
    }
    struct StatEntry: Decodable {
        let baseStat: Int
        let stat: NamedResource
        enum CodingKeys: String, CodingKey {
            case baseStat = "base_stat"; case stat
        }
    }
    struct AbilitySlot: Decodable {
        let slot: Int
        let ability: NamedResource
        let isHidden: Bool
        enum CodingKeys: String, CodingKey {
            case slot; case ability; case isHidden = "is_hidden"
        }
    }
    struct Sprites: Decodable {
        let frontDefault: String?
        let other: OtherSprites?
        enum CodingKeys: String, CodingKey { case frontDefault = "front_default"; case other }

        struct OtherSprites: Decodable {
            let officialArtwork: OfficialArtwork?
            enum CodingKeys: String, CodingKey { case officialArtwork = "official-artwork" }
            struct OfficialArtwork: Decodable {
                let frontDefault: String?
                enum CodingKeys: String, CodingKey { case frontDefault = "front_default" }
            }
        }
    }
}

private struct PokemonSpeciesResponse: Decodable {
    let isLegendary: Bool
    let isMythical: Bool
    let generation: NamedResource
    let evolutionChain: ChainReference?
    enum CodingKeys: String, CodingKey {
        case isLegendary = "is_legendary"; case isMythical = "is_mythical"
        case generation; case evolutionChain = "evolution_chain"
    }
    struct ChainReference: Decodable { let url: String }
}

private struct EvolutionChainResponse: Decodable {
    let chain: ChainLink
}

private struct ChainLink: Decodable {
    let species: NamedResource
    let evolvesTo: [ChainLink]
    enum CodingKeys: String, CodingKey { case species; case evolvesTo = "evolves_to" }
}

private struct AbilityResponse: Decodable {
    let effectEntries: [EffectEntry]
    enum CodingKeys: String, CodingKey { case effectEntries = "effect_entries" }
    struct EffectEntry: Decodable {
        let shortEffect: String
        let language: NamedResource
        enum CodingKeys: String, CodingKey { case shortEffect = "short_effect"; case language }
    }
}
