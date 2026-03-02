import SwiftUI
import SwiftData

/// Full Pokemon detail screen — stats, type chart, abilities, evolution, team fit analysis.
struct PokemonDetailView: View {
    let pokemon: CachedPokemon

    @Environment(\.modelContext) private var context
    @Query private var allTeams: [PokemonTeam]
    @State private var isLoading = false
    @State private var loadedPokemon: CachedPokemon?
    @State private var showTeamPicker = false
    @State private var abilityDescriptions: [String: String] = [:]

    private var activeTeam: PokemonTeam? { allTeams.first { $0.isActive } }

    // Use loaded data if available, otherwise fall back to stub
    private var displayPokemon: CachedPokemon { loadedPokemon ?? pokemon }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                // MARK: Header
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        PokemonSpriteView(url: displayPokemon.officialArtURL ?? displayPokemon.spriteURL, size: 160)
                        TypeBadgeRow(types: displayPokemon.types)
                        if displayPokemon.isLegendary {
                            Label("Legendary", systemImage: "star.fill").font(.caption).foregroundStyle(.yellow)
                        } else if displayPokemon.isMythical {
                            Label("Mythical", systemImage: "sparkles").font(.caption).foregroundStyle(.purple)
                        }
                    }
                    Spacer()
                }

                if isLoading {
                    ProgressView("Loading details…").frame(maxWidth: .infinity)
                }

                // MARK: Base Stats
                if displayPokemon.isFullyLoaded {
                    GroupBox("Base Stats") {
                        VStack(spacing: 6) {
                            StatBar(label: "HP",      value: displayPokemon.hp,             maxValue: 255)
                            StatBar(label: "Attack",  value: displayPokemon.attack,          maxValue: 255)
                            StatBar(label: "Defense", value: displayPokemon.defense,         maxValue: 255)
                            StatBar(label: "Sp. Atk", value: displayPokemon.specialAttack,   maxValue: 255)
                            StatBar(label: "Sp. Def", value: displayPokemon.specialDefense,  maxValue: 255)
                            StatBar(label: "Speed",   value: displayPokemon.speed,           maxValue: 255)
                            Divider()
                            HStack {
                                Text("Total").font(.caption.bold()).foregroundStyle(.secondary)
                                Spacer()
                                Text("\(displayPokemon.baseStatTotal)").font(.caption.bold())
                            }
                        }
                    }

                    // MARK: Type Matchup Chart
                    GroupBox("Type Matchups (Defending)") {
                        TypeMatchupGrid(types: displayPokemon.types)
                    }

                    // MARK: Abilities
                    GroupBox("Abilities") {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(displayPokemon.abilities, id: \.self) { ability in
                                AbilityRow(
                                    abilityName: ability,
                                    description: abilityDescriptions[ability]
                                ) {
                                    Task { await loadAbilityDescription(ability) }
                                }
                            }
                        }
                    }

                    // MARK: Team Fit Analysis
                    if let team = activeTeam {
                        GroupBox("How This Fits \(team.name)") {
                            TeamFitView(pokemon: displayPokemon, team: team, allPokemon: [])
                        }
                    }
                }

                // MARK: Add to Team button
                Button {
                    if allTeams.count == 1, let team = allTeams.first {
                        _ = team.addPokemon(id: displayPokemon.id)
                        try? context.save()
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
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
                .disabled(allTeams.isEmpty || activeTeam.map { $0.containsPokemon(id: displayPokemon.id) || $0.isFull } ?? false)
                .padding(.bottom)
            }
            .padding()
        }
        .navigationTitle("#\(displayPokemon.id) \(displayPokemon.displayName)")
        .navigationBarTitleDisplayMode(.large)
        .task { await loadFullData() }
        .sheet(isPresented: $showTeamPicker) {
            TeamPickerSheet(pokemon: displayPokemon)
        }
    }

    // MARK: - Loaders

    private func loadFullData() async {
        guard !pokemon.isFullyLoaded else {
            loadedPokemon = pokemon
            return
        }
        isLoading = true
        do {
            loadedPokemon = try await PokeAPIService.shared.loadFullPokemon(id: pokemon.id, context: context)
        } catch {
            print("Failed to load \(pokemon.name): \(error)")
        }
        isLoading = false
    }

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
                    _ = team.addPokemon(id: pokemon.id)
                    try? context.save()
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    dismiss()
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
