import SwiftUI
import SwiftData

/// Main Pokedex screen — grid of all Pokemon with search, filters, and team compatibility overlays.
struct PokedexView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \CachedPokemon.id) private var allPokemon: [CachedPokemon]
    @Query private var allTeams: [PokemonTeam]

    // Search & filter state
    @State private var searchText = ""
    @State private var selectedTypes: Set<String> = []
    @State private var selectedGen: Int = 0          // 0 = all
    @State private var showLegendaries = true
    @State private var sortOption: SortOption = .id
    @State private var showFilters = false

    // Stat minimum filters (empty string = no filter)
    @State private var minHP = ""
    @State private var minAttack = ""
    @State private var minDefense = ""
    @State private var minSpAtk = ""
    @State private var minSpDef = ""
    @State private var minSpeed = ""

    // For detail navigation
    @State private var selectedPokemon: CachedPokemon?

    enum SortOption: String, CaseIterable {
        case id = "#"
        case name = "A–Z"
        case bst = "BST"
        case speed = "Speed"
        case attack = "Attack"
    }

    // Active team (drives compatibility overlays)
    private var activeTeam: PokemonTeam? {
        allTeams.first { $0.isActive }
    }

    private var filteredPokemon: [CachedPokemon] {
        var result = allPokemon

        if !searchText.isEmpty {
            result = result.filter {
                $0.displayName.localizedCaseInsensitiveContains(searchText) ||
                $0.name.localizedCaseInsensitiveContains(searchText)
            }
        }

        if selectedGen > 0 {
            result = result.filter { $0.generation == selectedGen }
        }

        if !showLegendaries {
            result = result.filter { !$0.isLegendary && !$0.isMythical }
        }

        // Type filter — OR logic: show Pokemon that have any of the selected types
        if !selectedTypes.isEmpty {
            result = result.filter { !selectedTypes.isDisjoint(with: Set($0.types)) }
        }

        // Stat minimum filters
        if let val = Int(minHP),      val > 0 { result = result.filter { $0.hp >= val } }
        if let val = Int(minAttack),  val > 0 { result = result.filter { $0.attack >= val } }
        if let val = Int(minDefense), val > 0 { result = result.filter { $0.defense >= val } }
        if let val = Int(minSpAtk),   val > 0 { result = result.filter { $0.specialAttack >= val } }
        if let val = Int(minSpDef),   val > 0 { result = result.filter { $0.specialDefense >= val } }
        if let val = Int(minSpeed),   val > 0 { result = result.filter { $0.speed >= val } }

        // Sort
        switch sortOption {
        case .id:     result.sort { $0.id < $1.id }
        case .name:   result.sort { $0.displayName < $1.displayName }
        case .bst:    result.sort { $0.baseStatTotal > $1.baseStatTotal }
        case .speed:  result.sort { $0.speed > $1.speed }
        case .attack: result.sort { $0.attack > $1.attack }
        }

        return result
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter panel
                if showFilters {
                    FilterPanelView(
                        selectedTypes: $selectedTypes,
                        selectedGen: $selectedGen,
                        showLegendaries: $showLegendaries,
                        minHP: $minHP,
                        minAttack: $minAttack,
                        minDefense: $minDefense,
                        minSpAtk: $minSpAtk,
                        minSpDef: $minSpDef,
                        minSpeed: $minSpeed
                    )
                    .padding(.horizontal)
                }

                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 12) {
                        ForEach(filteredPokemon) { pokemon in
                            PokemonGridCard(
                                pokemon: pokemon,
                                activeTeam: activeTeam,
                                allTeams: allTeams,
                                allPokemon: allPokemon,
                                context: context
                            )
                            .onTapGesture { selectedPokemon = pokemon }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Pokédex")
            .searchable(text: $searchText, prompt: "Search Pokémon")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        withAnimation { showFilters.toggle() }
                    } label: {
                        Image(systemName: showFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Picker("Sort by", selection: $sortOption) {
                            ForEach(SortOption.allCases, id: \.self) { opt in
                                Text(opt.rawValue).tag(opt)
                            }
                        }
                    } label: {
                        Label("Sort", systemImage: "arrow.up.arrow.down")
                    }
                }
            }
            .navigationDestination(item: $selectedPokemon) { pokemon in
                PokemonDetailView(pokemon: pokemon)
            }
        }
    }
}

// MARK: - Grid Card

struct PokemonGridCard: View {
    let pokemon: CachedPokemon
    let activeTeam: PokemonTeam?
    let allTeams: [PokemonTeam]
    let allPokemon: [CachedPokemon]
    let context: ModelContext

    @State private var showQuickAdd = false

    private var compatibilityOverlay: CompatibilityStatus {
        guard let team = activeTeam else { return .none }
        if team.containsPokemon(id: pokemon.id) { return .onTeam }
        if team.isFull { return .none }
        guard !pokemon.types.isEmpty else { return .safeToAdd }
        let teamPokemon = team.pokemonIDs.compactMap { id in allPokemon.first { $0.id == id } }
        let beforeMap = TeamScorer.sharedWeaknessMap(team: teamPokemon)
        let afterMap  = TeamScorer.sharedWeaknessMap(team: teamPokemon + [pokemon])
        for (type_, afterCount) in afterMap where afterCount >= 2 {
            if (beforeMap[type_] ?? 0) < 2 { return .addsWeakness }
        }
        return .safeToAdd
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 4) {
                PokemonSpriteView(url: pokemon.spriteURL, size: 72)
                Text(pokemon.displayName)
                    .font(.caption.bold())
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                if !pokemon.types.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(pokemon.types, id: \.self) { type_ in
                            if let t = PokemonType(rawValue: type_) {
                                Text(t.displayName)
                                    .font(.system(size: 9, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 2)
                                    .background(t.color, in: Capsule())
                            }
                        }
                    }
                }
            }
            .padding(8)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))

            // Compatibility overlay badge
            if compatibilityOverlay != .none {
                compatibilityOverlay.badge
                    .offset(x: 4, y: -4)
            }
        }
        .contextMenu {
            if !allTeams.isEmpty {
                ForEach(allTeams) { team in
                    Button {
                        if team.addPokemon(id: pokemon.id) {
                            try? context.save()
                            if team.isFull {
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            } else {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            }
                        }
                    } label: {
                        Label("Add to \(team.name)", systemImage: "plus")
                    }
                    .disabled(team.containsPokemon(id: pokemon.id) || team.isFull)
                }
            }
        }
    }
}

enum CompatibilityStatus {
    case none, onTeam, safeToAdd, addsWeakness

    @ViewBuilder var badge: some View {
        switch self {
        case .onTeam:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green).background(.white, in: Circle())
        case .safeToAdd:
            Image(systemName: "plus.circle.fill")
                .foregroundStyle(.blue).background(.white, in: Circle())
        case .addsWeakness:
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundStyle(.orange).background(.white, in: Circle())
        case .none:
            EmptyView()
        }
    }
}

// MARK: - Filter Panel

struct FilterPanelView: View {
    @Binding var selectedTypes: Set<String>
    @Binding var selectedGen: Int
    @Binding var showLegendaries: Bool
    @Binding var minHP: String
    @Binding var minAttack: String
    @Binding var minDefense: String
    @Binding var minSpAtk: String
    @Binding var minSpDef: String
    @Binding var minSpeed: String

    private let types = PokemonType.allCases
    private let gens = Array(1...9)

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            // Type filter — tap to toggle, OR logic
            VStack(alignment: .leading, spacing: 6) {
                Text("Type").font(.caption.bold()).foregroundStyle(.secondary)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(types) { type_ in
                            Button {
                                if selectedTypes.contains(type_.rawValue) {
                                    selectedTypes.remove(type_.rawValue)
                                } else {
                                    selectedTypes.insert(type_.rawValue)
                                }
                            } label: {
                                Text(type_.displayName)
                                    .font(.caption.bold())
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(
                                        selectedTypes.contains(type_.rawValue) ? type_.color : type_.color.opacity(0.35),
                                        in: Capsule()
                                    )
                            }
                        }
                    }
                }
            }

            // Generation filter
            VStack(alignment: .leading, spacing: 6) {
                Text("Generation").font(.caption.bold()).foregroundStyle(.secondary)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        genChip(label: "All", value: 0)
                        ForEach(gens, id: \.self) { g in genChip(label: "Gen \(g)", value: g) }
                    }
                }
            }

            // Min stat filters — number inputs in a 2-column grid
            VStack(alignment: .leading, spacing: 6) {
                Text("Min Stats").font(.caption.bold()).foregroundStyle(.secondary)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    StatMinField(label: "HP",     value: $minHP)
                    StatMinField(label: "Atk",    value: $minAttack)
                    StatMinField(label: "Def",    value: $minDefense)
                    StatMinField(label: "Sp.Atk", value: $minSpAtk)
                    StatMinField(label: "Sp.Def", value: $minSpDef)
                    StatMinField(label: "Speed",  value: $minSpeed)
                }
            }

            // Legendary toggle
            Toggle("Show Legendaries & Mythicals", isOn: $showLegendaries)
                .font(.caption)
        }
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private func genChip(label: String, value: Int) -> some View {
        Button { selectedGen = value } label: {
            Text(label)
                .font(.caption.bold())
                .foregroundStyle(selectedGen == value ? .white : .primary)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(selectedGen == value ? Color.blue : Color(.secondarySystemBackground), in: Capsule())
        }
    }
}

// MARK: - Stat min input field

struct StatMinField: View {
    let label: String
    @Binding var value: String

    var body: some View {
        HStack(spacing: 6) {
            Text(label)
                .font(.caption.bold())
                .foregroundStyle(.secondary)
                .frame(width: 44, alignment: .leading)
            TextField("0", text: $value)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.numberPad)
                .font(.caption.monospacedDigit())
        }
    }
}
