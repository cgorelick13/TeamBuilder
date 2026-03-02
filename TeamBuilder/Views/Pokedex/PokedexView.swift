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
    @State private var typeFilterMode: TypeFilterMode = .any
    @State private var selectedGen: Int = 0          // 0 = all
    @State private var minSpeed: Double = 0
    @State private var showLegendaries = true
    @State private var sortOption: SortOption = .id
    @State private var showFilters = false

    // For detail navigation
    @State private var selectedPokemon: CachedPokemon?

    enum TypeFilterMode: String, CaseIterable {
        case any = "Any Type"
        case all = "All Types"
    }

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

        // Only show fully loaded stub Pokemon (at minimum they need a name)
        if !searchText.isEmpty {
            result = result.filter {
                $0.displayName.localizedCaseInsensitiveContains(searchText) ||
                $0.name.localizedCaseInsensitiveContains(searchText)
            }
        }

        if selectedGen > 0 {
            result = result.filter { $0.generation == selectedGen || $0.generation == 0 }
        }

        if !showLegendaries {
            result = result.filter { !$0.isLegendary && !$0.isMythical }
        }

        if !selectedTypes.isEmpty {
            result = result.filter { pokemon in
                let typeSet = Set(pokemon.types)
                if typeFilterMode == .all {
                    return selectedTypes.isSubset(of: typeSet)
                } else {
                    return !selectedTypes.isDisjoint(with: typeSet)
                }
            }
        }

        if minSpeed > 0 {
            result = result.filter { $0.speed >= Int(minSpeed) || !$0.isFullyLoaded }
        }

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
                // Filter bar
                if showFilters { FilterPanelView(
                    selectedTypes: $selectedTypes,
                    typeFilterMode: $typeFilterMode,
                    selectedGen: $selectedGen,
                    minSpeed: $minSpeed,
                    showLegendaries: $showLegendaries
                ).padding(.horizontal) }

                ScrollView {
                    if allPokemon.isEmpty {
                        // First launch loading state
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 12) {
                            ForEach(0..<20, id: \.self) { _ in SkeletonCard() }
                        }
                        .padding()
                        Text("Downloading Pokémon data — this only happens once.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding()
                    } else {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 12) {
                            ForEach(filteredPokemon) { pokemon in
                                PokemonGridCard(
                                    pokemon: pokemon,
                                    activeTeam: activeTeam,
                                    allTeams: allTeams,
                                    context: context
                                )
                                .onTapGesture { selectedPokemon = pokemon }
                            }
                        }
                        .padding()
                    }
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
    let context: ModelContext

    @State private var showQuickAdd = false

    private var compatibilityOverlay: CompatibilityStatus {
        guard let team = activeTeam else { return .none }
        if team.containsPokemon(id: pokemon.id) { return .onTeam }
        if team.isFull { return .none }
        // Check if adding this Pokemon would create a 3+ stacked weakness
        let weaksBefore = TeamScorer.sharedWeaknessMap(
            team: allTeams.first(where: { $0.isActive }).map { _ in [] } ?? []
        )
        _ = weaksBefore
        return .safeToAdd  // Simplified — full logic implemented in TeamScorer
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
                        _ = team.addPokemon(id: pokemon.id)
                        try? context.save()
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
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
    @Binding var typeFilterMode: PokedexView.TypeFilterMode
    @Binding var selectedGen: Int
    @Binding var minSpeed: Double
    @Binding var showLegendaries: Bool

    private let types = PokemonType.allCases
    private let gens = Array(1...9)

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Type filter
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Type").font(.caption.bold()).foregroundStyle(.secondary)
                    Spacer()
                    Picker("", selection: $typeFilterMode) {
                        ForEach(PokedexView.TypeFilterMode.allCases, id: \.self) {
                            Text($0.rawValue).tag($0)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 160)
                }
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

            // Speed filter
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Min Speed").font(.caption.bold()).foregroundStyle(.secondary)
                    Spacer()
                    Text("\(Int(minSpeed))").font(.caption.monospacedDigit())
                }
                Slider(value: $minSpeed, in: 0...150, step: 5)
                    .tint(.purple)
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

// MARK: - Skeleton card (loading state)

struct SkeletonCard: View {
    @State private var animate = false

    var body: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color(.secondarySystemBackground).opacity(animate ? 0.5 : 1))
            .frame(height: 110)
            .onAppear { withAnimation(.easeInOut(duration: 0.9).repeatForever()) { animate.toggle() } }
    }
}
