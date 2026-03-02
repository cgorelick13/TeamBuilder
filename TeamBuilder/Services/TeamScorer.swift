import Foundation

/// Calculates the 0–100 team score and generates fix suggestions and threat lists.
struct TeamScorer {

    // MARK: - Score breakdown

    struct ScoreResult {
        let total: Int            // 0–100
        let coverage: Int         // 0–40
        let defense: Int          // 0–35
        let stats: Int            // 0–25
        let suggestions: [String]
        let threats: [ThreatEntry]
    }

    struct ThreatEntry: Identifiable {
        let id = UUID()
        let pokemonName: String
        let reason: String
    }

    // MARK: - Main entry point

    static func score(team: [CachedPokemon]) -> ScoreResult {
        let coverage = scoreCoverage(team: team)
        let defense  = scoreDefense(team: team)
        let stats    = scoreStats(team: team)
        let suggestions = buildSuggestions(team: team)
        let threats = buildThreatList(team: team)

        return ScoreResult(
            total: coverage + defense + stats,
            coverage: coverage,
            defense: defense,
            stats: stats,
            suggestions: suggestions,
            threats: threats
        )
    }

    // MARK: - Coverage (40 pts)
    // Points for how many of the 18 types the team can hit super-effectively.

    static func scoreCoverage(team: [CachedPokemon]) -> Int {
        guard !team.isEmpty else { return 0 }
        let covered = coveredTypes(team: team).count
        return Int(Double(covered) / 18.0 * 40.0)
    }

    /// Returns the set of types the team can hit super-effectively
    static func coveredTypes(team: [CachedPokemon]) -> Set<PokemonType> {
        var covered: Set<PokemonType> = []
        // For each defending type, check if any team member's type hits it super-effectively
        for defendingType in PokemonType.allCases {
            for pokemon in team {
                let attackingTypes = pokemon.types.compactMap { PokemonType(rawValue: $0) }
                for atk in attackingTypes {
                    if TypeChart.effectiveness(attacking: atk, defending: defendingType) > 1.0 {
                        covered.insert(defendingType)
                    }
                }
            }
        }
        return covered
    }

    /// Returns types the team cannot hit super-effectively
    static func uncoveredTypes(team: [CachedPokemon]) -> [PokemonType] {
        let covered = coveredTypes(team: team)
        return PokemonType.allCases.filter { !covered.contains($0) }
    }

    // MARK: - Defense (35 pts)
    // Penalize shared weaknesses; reward for not having catastrophic weak points.

    static func scoreDefense(team: [CachedPokemon]) -> Int {
        guard !team.isEmpty else { return 0 }
        var penalty = 0

        let weaknessMap = sharedWeaknessMap(team: team)
        for (_, count) in weaknessMap {
            if count >= 3 { penalty += 10 }  // severe shared weakness
            else if count == 2 { penalty += 4 }
        }

        return max(0, 35 - penalty)
    }

    /// Returns a map of [type: number of Pokemon on the team weak to it]
    static func sharedWeaknessMap(team: [CachedPokemon]) -> [PokemonType: Int] {
        var map: [PokemonType: Int] = [:]
        for pokemon in team {
            let matchup = TypeChart.defensiveMatchup(for: pokemon.types)
            for (type_, multiplier) in matchup {
                if multiplier > 1.0 {
                    map[type_, default: 0] += 1
                }
            }
        }
        return map
    }

    /// Returns types that resist or are immune to at least 2 team members
    static func sharedResistances(team: [CachedPokemon]) -> [PokemonType] {
        var map: [PokemonType: Int] = [:]
        for pokemon in team {
            let matchup = TypeChart.defensiveMatchup(for: pokemon.types)
            for (type_, multiplier) in matchup {
                if multiplier < 1.0 {
                    map[type_, default: 0] += 1
                }
            }
        }
        return map.filter { $0.value >= 2 }.map { $0.key }.sorted { $0.rawValue < $1.rawValue }
    }

    // MARK: - Stat Balance (25 pts)
    // Reward for covering key combat roles.

    static func scoreStats(team: [CachedPokemon]) -> Int {
        guard !team.isEmpty else { return 0 }
        var pts = 0
        if team.contains(where: { $0.speed > 100 }) { pts += 7 }          // revenge killer / lead
        if team.contains(where: { $0.hp + $0.defense > 160 }) { pts += 6 } // physical wall
        if team.contains(where: { $0.specialAttack > 100 }) { pts += 6 }   // special sweeper
        if team.contains(where: { $0.attack > 100 }) { pts += 6 }          // physical sweeper
        return pts
    }

    // MARK: - Coverage heatmap data

    /// Returns the offensive multiplier the team can deal to each defending type
    /// (max across all team members' types)
    static func coverageHeatmap(team: [CachedPokemon]) -> [PokemonType: Double] {
        var result: [PokemonType: Double] = [:]
        for defending in PokemonType.allCases {
            var best = 0.0
            for pokemon in team {
                let atkTypes = pokemon.types.compactMap { PokemonType(rawValue: $0) }
                for atk in atkTypes {
                    let eff = TypeChart.effectiveness(attacking: atk, defending: defending)
                    if eff > best { best = eff }
                }
            }
            result[defending] = best
        }
        return result
    }

    // MARK: - Fix My Team suggestions

    private static func buildSuggestions(team: [CachedPokemon]) -> [String] {
        var suggestions: [String] = []

        // Shared weakness warnings (severity order)
        let weakMap = sharedWeaknessMap(team: team).sorted { $0.value > $1.value }
        for (type_, count) in weakMap where count >= 2 {
            let severity = count >= 3 ? "\(count) Pokemon" : "2 Pokemon"
            let counters = suggestedCounters(for: type_)
            suggestions.append("\(severity) are weak to \(type_.displayName) — consider adding \(counters)")
        }

        // Missing roles
        if !team.contains(where: { $0.speed > 100 }) {
            suggestions.append("No Pokemon faster than Speed 100 — consider a fast sweeper or revenge killer")
        }
        if !team.contains(where: { $0.hp + $0.defense > 160 }) {
            suggestions.append("No physical wall — consider adding a Pokemon with high HP and Defense")
        }
        if !team.contains(where: { $0.specialAttack > 100 }) {
            suggestions.append("No special attacker — consider adding a Pokemon with Sp. Atk > 100")
        }

        // Coverage gaps
        let uncovered = uncoveredTypes(team: team)
        if !uncovered.isEmpty && uncovered.count <= 4 {
            let names = uncovered.prefix(3).map { $0.displayName }.joined(separator: ", ")
            suggestions.append("No super-effective coverage against: \(names)")
        }

        // Incomplete team
        if team.count < 6 {
            let empty = 6 - team.count
            suggestions.append("\(empty) empty slot\(empty > 1 ? "s" : "") remaining")
        }

        return suggestions
    }

    /// Returns a brief string suggesting types that counter the given weakness
    private static func suggestedCounters(for weakType: PokemonType) -> String {
        // Types that resist or are immune to the given type
        let resistors = PokemonType.allCases.filter { def in
            TypeChart.effectiveness(attacking: weakType, defending: def) < 1.0
        }
        let names = resistors.prefix(2).map { $0.displayName }.joined(separator: " or ")
        return names.isEmpty ? "a resistance" : "a \(names) type"
    }

    // MARK: - Threat list (top 5 threatening Pokemon types)

    private static func buildThreatList(team: [CachedPokemon]) -> [ThreatEntry] {
        // Find types that hit the most team members super-effectively
        let weakMap = sharedWeaknessMap(team: team)
            .filter { $0.value >= 2 }
            .sorted { $0.value > $1.value }
            .prefix(5)

        return weakMap.map { (type_, count) in
            ThreatEntry(
                pokemonName: "\(type_.displayName)-type attackers",
                reason: "Hit \(count) of your \(team.count) Pokemon super-effectively"
            )
        }
    }
}
