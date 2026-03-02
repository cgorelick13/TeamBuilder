import Foundation
import SwiftData

/// A named team of up to 6 Pokemon, saved locally.
@Model
final class PokemonTeam {
    @Attribute(.unique) var id: UUID
    var name: String
    var formatTag: String      // e.g. "Casual", "VGC", "OU", "Nuzlocke"
    var pokemonIDs: [Int]      // ordered list of Pokemon IDs (max 6)
    var isActive: Bool         // true = drives Pokedex overlays + suggestions
    var createdAt: Date

    init(name: String, formatTag: String = "Casual") {
        self.id = UUID()
        self.name = name
        self.formatTag = formatTag
        self.pokemonIDs = []
        self.isActive = false
        self.createdAt = Date()
    }

    // MARK: - Computed

    var count: Int { pokemonIDs.count }
    var isFull: Bool { pokemonIDs.count >= 6 }
    var isEmpty: Bool { pokemonIDs.isEmpty }

    /// Add a Pokemon if there's room and it's not already on the team
    func addPokemon(id: Int) -> Bool {
        guard pokemonIDs.count < 6, !pokemonIDs.contains(id) else { return false }
        pokemonIDs.append(id)
        return true
    }

    func removePokemon(id: Int) {
        pokemonIDs.removeAll { $0 == id }
    }

    func containsPokemon(id: Int) -> Bool {
        pokemonIDs.contains(id)
    }

    /// Returns a duplicate with a new name (for the duplicate-team feature)
    func duplicate(newName: String) -> PokemonTeam {
        let copy = PokemonTeam(name: newName, formatTag: self.formatTag)
        copy.pokemonIDs = self.pokemonIDs
        return copy
    }
}

/// Format tags available in the team picker
enum TeamFormat: String, CaseIterable {
    case casual   = "Casual"
    case ou       = "OU"
    case vgc      = "VGC"
    case nuzlocke = "Nuzlocke"
    case ubers    = "Ubers"
    case nu       = "NU"
    case ru       = "RU"
    case uu       = "UU"
}
