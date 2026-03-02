import SwiftUI
import SwiftData

/// Full Pokemon detail screen — stats, type chart, abilities, evolution, team fit analysis.
struct PokemonDetailView: View {
    let pokemon: CachedPokemon

    @Environment(\.modelContext) private var context
    @Query private var allTeams: [PokemonTeam]
    @Query private var allPokemon: [CachedPokemon]
    @State private var showTeamPicker = false
    @State private var abilityDescriptions: [String: String] = [:]
    @State private var selectedEvolution: CachedPokemon?

    private var activeTeam: PokemonTeam? { allTeams.first { $0.isActive } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                // MARK: Header
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        PokemonSpriteView(url: pokemon.officialArtURL ?? pokemon.spriteURL, size: 160)
                        TypeBadgeRow(types: pokemon.types)
                        if pokemon.isLegendary {
                            Label("Legendary", systemImage: "star.fill").font(.caption).foregroundStyle(.yellow)
                        } else if pokemon.isMythical {
                            Label("Mythical", systemImage: "sparkles").font(.caption).foregroundStyle(.purple)
                        }
                    }
                    Spacer()
                }

                // MARK: Base Stats
                if pokemon.isFullyLoaded {
                    GroupBox("Base Stats") {
                        VStack(spacing: 6) {
                            StatBar(label: "HP",      value: pokemon.hp,             maxValue: 255)
                            StatBar(label: "Attack",  value: pokemon.attack,          maxValue: 255)
                            StatBar(label: "Defense", value: pokemon.defense,         maxValue: 255)
                            StatBar(label: "Sp. Atk", value: pokemon.specialAttack,   maxValue: 255)
                            StatBar(label: "Sp. Def", value: pokemon.specialDefense,  maxValue: 255)
                            StatBar(label: "Speed",   value: pokemon.speed,           maxValue: 255)
                            Divider()
                            HStack {
                                Text("Total").font(.caption.bold()).foregroundStyle(.secondary)
                                Spacer()
                                Text("\(pokemon.baseStatTotal)").font(.caption.bold())
                            }
                        }
                    }

                    // MARK: Type Matchup Chart
                    GroupBox("Type Matchups (Defending)") {
                        TypeMatchupGrid(types: pokemon.types)
                    }

                    // MARK: Abilities
                    GroupBox("Abilities") {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(pokemon.abilities, id: \.self) { ability in
                                AbilityRow(
                                    abilityName: ability,
                                    description: abilityDescriptions[ability]
                                ) {
                                    Task { await loadAbilityDescription(ability) }
                                }
                            }
                        }
                    }

                    // MARK: Evolution Chain
                    let chainIDs = pokemon.evolutionChainIDs
                    if chainIDs.count > 1 {
                        GroupBox("Evolution Chain") {
                            EvolutionChainView(
                                evolutionChainIDs: chainIDs,
                                currentID: pokemon.id,
                                allPokemon: allPokemon,
                                onSelect: { selectedEvolution = $0 }
                            )
                        }
                    }

                    // MARK: Team Fit Analysis
                    if let team = activeTeam {
                        GroupBox("How This Fits \(team.name)") {
                            TeamFitView(pokemon: pokemon, team: team, allPokemon: [])
                        }
                    }
                }

                // MARK: Add to Team button
                Button {
                    if allTeams.count == 1, let team = allTeams.first {
                        if team.addPokemon(id: pokemon.id) {
                            try? context.save()
                            if team.isFull {
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            } else {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            }
                        }
                    } else {
                        showTeamPicker = true
                    }
                } label: {
                    Label(
                        activeTeam.map { "Add to \($0.name)" } ?? "Add to Team",
                        systemImage: "plus.circle.fill"
                    )
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(allTeams.isEmpty || activeTeam.map { $0.containsPokemon(id: pokemon.id) || $0.isFull } ?? false)
                .padding(.bottom)
            }
            .padding()
        }
        .navigationTitle("#\(pokemon.id) \(pokemon.displayName)")
        .navigationBarTitleDisplayMode(.large)
        .navigationDestination(item: $selectedEvolution) { evo in
            PokemonDetailView(pokemon: evo)
        }
        .sheet(isPresented: $showTeamPicker) {
            TeamPickerSheet(pokemon: pokemon)
        }
    }

    // MARK: - Loaders

    private func loadAbilityDescription(_ name: String) async {
        guard abilityDescriptions[name] == nil else { return }
        if let desc = try? await PokeAPIService.shared.abilityDescription(name: name) {
            abilityDescriptions[name] = desc
        }
    }
}

// MARK: - Type Matchup Grid (18-type defensive chart)

struct TypeMatchupGrid: View {
    let types: [String]

    private var matchup: [PokemonType: Double] { TypeChart.defensiveMatchup(for: types) }

    private let columns = Array(repeating: GridItem(.flexible()), count: 6)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 6) {
            ForEach(PokemonType.allCases) { type_ in
                let mult = matchup[type_] ?? 1.0
                VStack(spacing: 2) {
                    Text(type_.displayName.prefix(3))
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white)
                    Text(multLabel(mult))
                        .font(.system(size: 10, weight: .heavy))
                        .foregroundStyle(multColor(mult))
                }
                .padding(.vertical, 4)
                .frame(maxWidth: .infinity)
                .background(type_.color.opacity(0.7), in: RoundedRectangle(cornerRadius: 6))
            }
        }
    }

    private func multLabel(_ m: Double) -> String {
        switch m {
        case 0: return "0×"
        case 0.25: return "¼×"
        case 0.5: return "½×"
        case 2: return "2×"
        case 4: return "4×"
        default: return "1×"
        }
    }

    private func multColor(_ m: Double) -> Color {
        switch m {
        case 0, 0.25, 0.5: return .green
        case 2, 4:          return .red
        default:            return .white
        }
    }
}

// MARK: - Ability Row (tap to expand description)

struct AbilityRow: View {
    let abilityName: String
    let description: String?
    let onExpand: () -> Void

    @State private var isExpanded = false

    var displayName: String {
        abilityName.split(separator: "-").map { $0.capitalized }.joined(separator: " ")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Button {
                if description == nil { onExpand() }
                withAnimation { isExpanded.toggle() }
            } label: {
                HStack {
                    Text(displayName).font(.subheadline.bold())
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            .foregroundStyle(.primary)

            if isExpanded {
                if let desc = description {
                    Text(desc).font(.caption).foregroundStyle(.secondary)
                } else {
                    ProgressView().scaleEffect(0.7)
                }
            }
        }
    }
}

// MARK: - Team Fit View

struct TeamFitView: View {
    let pokemon: CachedPokemon
    let team: PokemonTeam
    let allPokemon: [CachedPokemon]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            let newTypes = TypeChart.superEffectiveTypes(against: pokemon.types)
            if !newTypes.isEmpty {
                Label("Brings \(newTypes.count) type(s) this Pokemon can hit super-effectively", systemImage: "bolt.fill")
                    .font(.caption).foregroundStyle(.green)
            }
            if pokemon.speed > 100 {
                Label("Adds a fast Pokemon (Speed \(pokemon.speed))", systemImage: "hare.fill")
                    .font(.caption).foregroundStyle(.blue)
            }
            if pokemon.specialAttack > 100 {
                Label("Fills special attacker role (Sp. Atk \(pokemon.specialAttack))", systemImage: "sparkles")
                    .font(.caption).foregroundStyle(.purple)
            }
        }
    }
}

// MARK: - Evolution Chain View

struct EvolutionChainView: View {
    let evolutionChainIDs: [Int]
    let currentID: Int
    let allPokemon: [CachedPokemon]
    let onSelect: (CachedPokemon) -> Void

    private var chainPokemon: [CachedPokemon] {
        evolutionChainIDs.compactMap { id in allPokemon.first { $0.id == id } }
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                ForEach(Array(chainPokemon.enumerated()), id: \.element.id) { index, poke in
                    if index > 0 {
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 2)
                    }
                    Button {
                        if poke.id != currentID { onSelect(poke) }
                    } label: {
                        VStack(spacing: 4) {
                            PokemonSpriteView(url: poke.spriteURL, size: 60)
                            Text(poke.displayName)
                                .font(.system(size: 10, weight: .bold))
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                                .frame(maxWidth: 68)
                        }
                        .padding(6)
                        .background(
                            poke.id == currentID
                                ? Color.blue.opacity(0.12)
                                : Color(.secondarySystemBackground),
                            in: RoundedRectangle(cornerRadius: 10)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(poke.id == currentID ? Color.blue : Color.clear, lineWidth: 1.5)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
        }
    }
}

// MARK: - Team Picker Sheet

struct TeamPickerSheet: View {
    let pokemon: CachedPokemon
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query private var allTeams: [PokemonTeam]

    var body: some View {
        NavigationStack {
            List(allTeams) { team in
                Button {
                    if team.addPokemon(id: pokemon.id) {
                        try? context.save()
                        if team.isFull {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        } else {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                        dismiss()
                    }
                } label: {
                    HStack {
                        Text(team.name)
                        Spacer()
                        Text("\(team.count)/6").foregroundStyle(.secondary)
                    }
                }
                .disabled(team.containsPokemon(id: pokemon.id) || team.isFull)
            }
            .navigationTitle("Add to Team")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
