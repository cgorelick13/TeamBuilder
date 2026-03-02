import Foundation
import SwiftUI

/// All 18 Pokemon types
enum PokemonType: String, CaseIterable, Identifiable {
    case normal, fire, water, electric, grass, ice
    case fighting, poison, ground, flying, psychic, bug
    case rock, ghost, dragon, dark, steel, fairy

    var id: String { rawValue }

    var displayName: String { rawValue.capitalized }

    /// Official type color (Bulbapedia palette)
    var color: Color {
        switch self {
        case .normal:   return Color(hex: "#A8A878")
        case .fire:     return Color(hex: "#F08030")
        case .water:    return Color(hex: "#6890F0")
        case .electric: return Color(hex: "#F8D030")
        case .grass:    return Color(hex: "#78C850")
        case .ice:      return Color(hex: "#98D8D8")
        case .fighting: return Color(hex: "#C03028")
        case .poison:   return Color(hex: "#A040A0")
        case .ground:   return Color(hex: "#E0C068")
        case .flying:   return Color(hex: "#A890F0")
        case .psychic:  return Color(hex: "#F85888")
        case .bug:      return Color(hex: "#A8B820")
        case .rock:     return Color(hex: "#B8A038")
        case .ghost:    return Color(hex: "#705898")
        case .dragon:   return Color(hex: "#7038F8")
        case .dark:     return Color(hex: "#705848")
        case .steel:    return Color(hex: "#B8B8D0")
        case .fairy:    return Color(hex: "#EE99AC")
        }
    }
}

/// Lookup: given an attacking type, returns the multiplier against each defending type
/// Usage: TypeChart.effectiveness(attacking: .fire, defending: .grass) → 2.0
struct TypeChart {

    // Full 18x18 effectiveness table.
    // Outer key = attacking type, inner key = defending type, value = multiplier
    static let table: [PokemonType: [PokemonType: Double]] = buildTable()

    static func effectiveness(attacking: PokemonType, defending: PokemonType) -> Double {
        table[attacking]?[defending] ?? 1.0
    }

    /// Multiplier an attacking type deals against a dual-type defender
    static func effectiveness(attacking: PokemonType, defendingTypes: [PokemonType]) -> Double {
        defendingTypes.reduce(1.0) { $0 * effectiveness(attacking: attacking, defending: $1) }
    }

    /// All types this attacking type hits super-effectively (>1x) vs a defender
    static func superEffectiveTypes(against defenderTypes: [String]) -> [PokemonType] {
        let defs = defenderTypes.compactMap { PokemonType(rawValue: $0) }
        return PokemonType.allCases.filter { atk in
            effectiveness(attacking: atk, defendingTypes: defs) > 1.0
        }
    }

    /// Full defensive matchup for a Pokemon: multiplier each attacking type deals to it
    static func defensiveMatchup(for defenderTypes: [String]) -> [PokemonType: Double] {
        let defs = defenderTypes.compactMap { PokemonType(rawValue: $0) }
        var result: [PokemonType: Double] = [:]
        for atk in PokemonType.allCases {
            result[atk] = effectiveness(attacking: atk, defendingTypes: defs)
        }
        return result
    }

    // MARK: - Raw table data

    private static func buildTable() -> [PokemonType: [PokemonType: Double]] {
        // Rows = attacking type, columns = defending type
        // Values: 0 = immune, 0.5 = not very effective, 1 = normal, 2 = super effective
        typealias T = PokemonType
        var t: [T: [T: Double]] = [:]
        for atk in T.allCases { t[atk] = [:] }

        // Normal
        t[.normal]![.rock] = 0.5; t[.normal]![.steel] = 0.5; t[.normal]![.ghost] = 0

        // Fire
        t[.fire]![.fire] = 0.5; t[.fire]![.water] = 0.5; t[.fire]![.rock] = 0.5; t[.fire]![.dragon] = 0.5
        t[.fire]![.grass] = 2; t[.fire]![.ice] = 2; t[.fire]![.bug] = 2; t[.fire]![.steel] = 2

        // Water
        t[.water]![.water] = 0.5; t[.water]![.grass] = 0.5; t[.water]![.dragon] = 0.5
        t[.water]![.fire] = 2; t[.water]![.ground] = 2; t[.water]![.rock] = 2

        // Electric
        t[.electric]![.electric] = 0.5; t[.electric]![.grass] = 0.5; t[.electric]![.dragon] = 0.5
        t[.electric]![.ground] = 0
        t[.electric]![.water] = 2; t[.electric]![.flying] = 2

        // Grass
        t[.grass]![.fire] = 0.5; t[.grass]![.grass] = 0.5; t[.grass]![.poison] = 0.5
        t[.grass]![.flying] = 0.5; t[.grass]![.bug] = 0.5; t[.grass]![.dragon] = 0.5; t[.grass]![.steel] = 0.5
        t[.grass]![.water] = 2; t[.grass]![.ground] = 2; t[.grass]![.rock] = 2

        // Ice
        t[.ice]![.water] = 0.5; t[.ice]![.ice] = 0.5; t[.ice]![.steel] = 0.5
        t[.ice]![.grass] = 2; t[.ice]![.ground] = 2; t[.ice]![.flying] = 2; t[.ice]![.dragon] = 2

        // Fighting
        t[.fighting]![.poison] = 0.5; t[.fighting]![.flying] = 0.5; t[.fighting]![.psychic] = 0.5
        t[.fighting]![.bug] = 0.5; t[.fighting]![.fairy] = 0.5; t[.fighting]![.ghost] = 0
        t[.fighting]![.normal] = 2; t[.fighting]![.ice] = 2; t[.fighting]![.rock] = 2
        t[.fighting]![.dark] = 2; t[.fighting]![.steel] = 2

        // Poison
        t[.poison]![.poison] = 0.5; t[.poison]![.ground] = 0.5; t[.poison]![.rock] = 0.5
        t[.poison]![.ghost] = 0.5; t[.poison]![.steel] = 0
        t[.poison]![.grass] = 2; t[.poison]![.fairy] = 2

        // Ground
        t[.ground]![.grass] = 0.5; t[.ground]![.bug] = 0.5; t[.ground]![.flying] = 0
        t[.ground]![.fire] = 2; t[.ground]![.electric] = 2; t[.ground]![.poison] = 2
        t[.ground]![.rock] = 2; t[.ground]![.steel] = 2

        // Flying
        t[.flying]![.electric] = 0.5; t[.flying]![.rock] = 0.5; t[.flying]![.steel] = 0.5
        t[.flying]![.grass] = 2; t[.flying]![.fighting] = 2; t[.flying]![.bug] = 2

        // Psychic
        t[.psychic]![.psychic] = 0.5; t[.psychic]![.steel] = 0.5; t[.psychic]![.dark] = 0
        t[.psychic]![.fighting] = 2; t[.psychic]![.poison] = 2

        // Bug
        t[.bug]![.fire] = 0.5; t[.bug]![.fighting] = 0.5; t[.bug]![.flying] = 0.5
        t[.bug]![.ghost] = 0.5; t[.bug]![.steel] = 0.5; t[.bug]![.fairy] = 0.5
        t[.bug]![.grass] = 2; t[.bug]![.psychic] = 2; t[.bug]![.dark] = 2

        // Rock
        t[.rock]![.fighting] = 0.5; t[.rock]![.ground] = 0.5; t[.rock]![.steel] = 0.5
        t[.rock]![.fire] = 2; t[.rock]![.ice] = 2; t[.rock]![.flying] = 2; t[.rock]![.bug] = 2

        // Ghost
        t[.ghost]![.normal] = 0; t[.ghost]![.dark] = 0.5
        t[.ghost]![.ghost] = 2; t[.ghost]![.psychic] = 2

        // Dragon
        t[.dragon]![.steel] = 0.5; t[.dragon]![.fairy] = 0
        t[.dragon]![.dragon] = 2

        // Dark
        t[.dark]![.fighting] = 0.5; t[.dark]![.dark] = 0.5; t[.dark]![.fairy] = 0.5
        t[.dark]![.ghost] = 2; t[.dark]![.psychic] = 2

        // Steel
        t[.steel]![.fire] = 0.5; t[.steel]![.water] = 0.5; t[.steel]![.electric] = 0.5
        t[.steel]![.steel] = 0.5
        t[.steel]![.ice] = 2; t[.steel]![.rock] = 2; t[.steel]![.fairy] = 2

        // Fairy
        t[.fairy]![.fire] = 0.5; t[.fairy]![.poison] = 0.5; t[.fairy]![.steel] = 0.5
        t[.fairy]![.dragon] = 0
        t[.fairy]![.fighting] = 2; t[.fairy]![.dark] = 2; t[.fairy]![.dragon] = 2

        return t
    }
}

// MARK: - Color hex helper

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
