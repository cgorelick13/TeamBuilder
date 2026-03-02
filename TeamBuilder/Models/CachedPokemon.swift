import Foundation
import SwiftData

/// Locally cached Pokemon data fetched from PokeAPI.
/// Stored in SwiftData so the app works offline after first load.
@Model
final class CachedPokemon {
    // MARK: - Identity
    @Attribute(.unique) var id: Int
    var name: String          // e.g. "charizard"
    var displayName: String   // e.g. "Charizard"

    // MARK: - Types (e.g. ["fire", "flying"])
    var types: [String]

    // MARK: - Base Stats
    var hp: Int
    var attack: Int
    var defense: Int
    var specialAttack: Int
    var specialDefense: Int
    var speed: Int

    // MARK: - Abilities (e.g. ["blaze", "solar-power"])
    var abilities: [String]

    // MARK: - Sprites
    var spriteURL: String?        // front default sprite
    var officialArtURL: String?   // official artwork

    // MARK: - Meta
    var generation: Int           // 1–9
    var isLegendary: Bool
    var isMythical: Bool

    // MARK: - Evolution chain (ordered list of Pokemon IDs)
    var evolutionChainIDs: [Int]

    // MARK: - Fetch status
    var isFullyLoaded: Bool  // false = only name/id loaded, true = full data cached

    init(id: Int, name: String) {
        self.id = id
        self.name = name
        self.displayName = name.capitalized.replacingOccurrences(of: "-", with: " ")
        self.types = []
        self.hp = 0
        self.attack = 0
        self.defense = 0
        self.specialAttack = 0
        self.specialDefense = 0
        self.speed = 0
        self.abilities = []
        self.spriteURL = nil
        self.officialArtURL = nil
        self.generation = 0
        self.isLegendary = false
        self.isMythical = false
        self.evolutionChainIDs = []
        self.isFullyLoaded = false
    }

    // MARK: - Computed helpers

    var baseStatTotal: Int {
        hp + attack + defense + specialAttack + specialDefense + speed
    }

    /// Role inferred from stats — used for team slot labels
    var role: PokemonRole {
        if speed > 100 && (attack > 100 || specialAttack > 100) { return .sweeper }
        if (hp + defense) > 160 { return .tank }
        if specialAttack > 100 { return .specialAttacker }
        if attack > 100 { return .physicalAttacker }
        if specialDefense > 100 { return .support }
        return .pivot
    }
}

/// Broad combat role label shown on team slots
enum PokemonRole: String {
    case sweeper         = "Sweeper"
    case tank            = "Tank"
    case specialAttacker = "Sp. Attacker"
    case physicalAttacker = "Attacker"
    case support         = "Support"
    case pivot           = "Pivot"
}
