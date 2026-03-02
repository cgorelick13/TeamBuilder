import SwiftUI
import SwiftData

/// Team detail screen — slots, score, heatmap, weaknesses, suggestions, threats, export.
struct TeamDetailView: View {
    @Bindable var team: PokemonTeam
    @Environment(\.modelContext) private var context
    @Query private var allPokemon: [CachedPokemon]

    @State private var showPokedex = false
    @State private var showExport = false
    @State private var showImport = false
    @State private var exportText = ""
    @State private var scoreResult: TeamScorer.ScoreResult = TeamScorer.score(team: [])

    private var teamPokemon: [CachedPokemon] {
        team.pokemonIDs.compactMap { id in allPokemon.first { $0.id == id } }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                // MARK: Pokemon Slots
                GroupBox {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                        ForEach(0..<6, id: \.self) { index in
                            if index < teamPokemon.count {
                                FilledSlotView(pokemon: teamPokemon[index]) {
                                    team.removePokemon(id: teamPokemon[index].id)
                                    try? context.save()
                                    recalculate()
                                }
                            } else {
                                EmptySlotView { showPokedex = true }
                            }
                        }
                    }
                } label: {
                    Label("Team (\(team.count)/6)", systemImage: "person.3.fill")
                }

                // MARK: Speed Order
                if !teamPokemon.isEmpty {
                    GroupBox("Speed Order") {
                        VStack(spacing: 4) {
                            ForEach(teamPokemon.sorted { $0.speed > $1.speed }) { pokemon in
                                HStack {
                                    PokemonSpriteView(url: pokemon.spriteURL, size: 28)
                                    Text(pokemon.displayName).font(.caption)
                                    Spacer()
                                    Text("\(pokemon.speed)")
                                        .font(.caption.bold().monospacedDigit())
                                        .foregroundStyle(.purple)
                                    GeometryReader { geo in
                                        Capsule().fill(Color.purple.opacity(0.3))
                                        Capsule().fill(Color.purple)
                                            .frame(width: geo.size.width * Double(pokemon.speed) / 150.0)
                                    }
                                    .frame(height: 6)
                                }
                            }
                        }
                    }
                }

                // MARK: Team Score
                GroupBox {
                    VStack(spacing: 8) {
                        Text("\(scoreResult.total)")
                            .font(.system(size: 64, weight: .black))
                            .foregroundStyle(scoreColor(scoreResult.total))
                        Text("out of 100")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        HStack(spacing: 20) {
                            ScoreChip(label: "Coverage", value: scoreResult.coverage, max: 40, color: .blue)
                            ScoreChip(label: "Defense",  value: scoreResult.defense,  max: 35, color: .green)
                            ScoreChip(label: "Stats",    value: scoreResult.stats,    max: 25, color: .purple)
                        }
                    }
                    .frame(maxWidth: .infinity)
                } label: {
                    Label("Team Score", systemImage: "chart.bar.fill")
                }

                // MARK: Type Coverage Heatmap
                GroupBox("Type Coverage") {
                    TypeCoverageHeatmap(team: teamPokemon)
                }

                // MARK: Shared Weaknesses
                let weakMap = TeamScorer.sharedWeaknessMap(team: teamPokemon)
                    .filter { $0.value >= 2 }
                    .sorted { $0.value > $1.value }

                if !weakMap.isEmpty {
                    GroupBox("Shared Weaknesses") {
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(weakMap, id: \.key) { (type_, count) in
                                HStack(spacing: 8) {
                                    Circle()
                                        .fill(count >= 3 ? Color.red : Color.orange)
                                        .frame(width: 8, height: 8)
                                    TypeBadge(typeName: type_.rawValue)
                                    Text("— \(count) Pokemon weak")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }

                // MARK: Resistances
                let resistances = TeamScorer.sharedResistances(team: teamPokemon)
                if !resistances.isEmpty {
                    GroupBox("Resistances") {
                        FlowLayout(spacing: 6) {
                            ForEach(resistances) { TypeBadge(typeName: $0.rawValue) }
                        }
                    }
                }

                // MARK: Fix My Team Suggestions
                if !scoreResult.suggestions.isEmpty {
                    GroupBox("Fix My Team") {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(scoreResult.suggestions, id: \.self) { suggestion in
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "bolt.fill")
                                        .foregroundStyle(.yellow)
                                        .font(.caption)
                                        .padding(.top, 2)
                                    Text(suggestion).font(.caption)
                                }
                            }
                        }
                    }
                }

                // MARK: Threat List
                if !scoreResult.threats.isEmpty {
                    GroupBox("Threat List") {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(Array(scoreResult.threats.enumerated()), id: \.offset) { index, threat in
                                HStack(alignment: .top, spacing: 8) {
                                    Text("\(index + 1).")
                                        .font(.caption.bold())
                                        .foregroundStyle(.red)
                                        .frame(width: 18, alignment: .trailing)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(threat.pokemonName).font(.caption.bold())
                                        Text(threat.reason).font(.caption).foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle(team.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { showExport = true } label: {
                        Label("Export Showdown Paste", systemImage: "square.and.arrow.up")
                    }
                    Button { showImport = true } label: {
                        Label("Import Showdown Paste", systemImage: "square.and.arrow.down")
                    }
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
        .sheet(isPresented: $showPokedex) {
            PokedexPickerSheet(team: team)
        }
        .sheet(isPresented: $showExport) {
            ShowdownExportSheet(team: team, pokemon: teamPokemon)
        }
        .sheet(isPresented: $showImport) {
            ShowdownImportSheet(team: team)
        }
        .onAppear { recalculate() }
        .onChange(of: team.pokemonIDs) { recalculate() }
    }

    private func recalculate() {
        withAnimation { scoreResult = TeamScorer.score(team: teamPokemon) }
    }

    private func scoreColor(_ score: Int) -> Color {
        switch score {
        case 80...100: return .green
        case 60...79:  return .yellow
        default:       return .red
        }
    }
}

// MARK: - Slot Views

struct FilledSlotView: View {
    let pokemon: CachedPokemon
    let onRemove: () -> Void

    var body: some View {
        VStack(spacing: 4) {
            PokemonSpriteView(url: pokemon.spriteURL, size: 56)
            Text(pokemon.displayName)
                .font(.system(size: 11, weight: .bold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(pokemon.role.rawValue)
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
        }
        .padding(8)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
        .contextMenu {
            Button(role: .destructive, action: onRemove) {
                Label("Remove", systemImage: "trash")
            }
        }
    }
}

struct EmptySlotView: View {
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Image(systemName: "plus.circle.dashed")
                    .font(.system(size: 32))
                    .foregroundStyle(.secondary)
                Text("Add")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, minHeight: 90)
            .background(Color(.tertiarySystemFill), in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Score Chip

struct ScoreChip: View {
    let label: String
    let value: Int
    let max: Int
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text("\(value)/\(max)").font(.caption.bold()).foregroundStyle(color)
            Text(label).font(.system(size: 10)).foregroundStyle(.secondary)
        }
    }
}

// MARK: - Type Coverage Heatmap

struct TypeCoverageHeatmap: View {
    let team: [CachedPokemon]

    private var heatmap: [PokemonType: Double] { TeamScorer.coverageHeatmap(team: team) }
    private let columns = Array(repeating: GridItem(.flexible()), count: 6)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 6) {
            ForEach(PokemonType.allCases) { type_ in
                let mult = heatmap[type_] ?? 0
                VStack(spacing: 2) {
                    Text(type_.displayName.prefix(3))
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white)
                    Text(cellLabel(mult))
                        .font(.system(size: 9, weight: .heavy))
                        .foregroundStyle(cellFg(mult))
                }
                .padding(.vertical, 4)
                .frame(maxWidth: .infinity)
                .background(cellBg(mult).opacity(0.8), in: RoundedRectangle(cornerRadius: 6))
            }
        }

        // Legend
        HStack(spacing: 12) {
            ForEach(["2× Super", "1× Neutral", "<1× Weak", "0× None"], id: \.self) { label in
                HStack(spacing: 4) {
                    Circle().fill(legendColor(label)).frame(width: 8, height: 8)
                    Text(label).font(.system(size: 9)).foregroundStyle(.secondary)
                }
            }
        }
        .padding(.top, 4)
    }

    private func cellLabel(_ m: Double) -> String {
        switch m {
        case 0:    return "✕"
        case 0.5:  return "½×"
        case 2, 4: return "2×"
        default:   return "1×"
        }
    }

    private func cellBg(_ m: Double) -> Color {
        switch m {
        case 0:       return .gray
        case 0.5:     return .yellow
        case 2...:    return .green
        default:      return Color(.systemFill)
        }
    }

    private func cellFg(_ m: Double) -> Color {
        switch m {
        case 0:    return .white
        case 0.5:  return .black
        default:   return .white
        }
    }

    private func legendColor(_ label: String) -> Color {
        switch label {
        case "2× Super":  return .green
        case "1× Neutral": return Color(.systemFill)
        case "<1× Weak":  return .yellow
        default:           return .gray
        }
    }
}

// MARK: - Pokedex Picker Sheet

struct PokedexPickerSheet: View {
    let team: PokemonTeam
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    var body: some View {
        NavigationStack {
            PokedexView()
                .navigationTitle("Pick a Pokémon")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Done") { dismiss() }
                    }
                }
        }
    }
}

// MARK: - Showdown Export

struct ShowdownExportSheet: View {
    let team: PokemonTeam
    let pokemon: [CachedPokemon]
    @Environment(\.dismiss) private var dismiss

    private var paste: String {
        pokemon.map { p in
            "\(p.displayName)\nAbility: \(p.abilities.first.map { $0.split(separator: "-").map { $0.capitalized }.joined(separator: " ") } ?? "None")\n"
        }.joined(separator: "\n")
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                Text(paste)
                    .font(.system(.body, design: .monospaced))
                    .padding()
                    .textSelection(.enabled)
            }
            .navigationTitle("Showdown Export")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    ShareLink(item: paste) { Label("Share", systemImage: "square.and.arrow.up") }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Showdown Import

struct ShowdownImportSheet: View {
    let team: PokemonTeam
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query private var allPokemon: [CachedPokemon]

    @State private var pasteText = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                TextEditor(text: $pasteText)
                    .font(.system(.body, design: .monospaced))
                    .border(Color(.separator))
                    .padding()
                Text("Paste a Pokémon Showdown team export above. The app will match Pokémon names to your local data.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
            }
            .navigationTitle("Import from Showdown")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Import") {
                        importPaste()
                        dismiss()
                    }
                    .disabled(pasteText.isEmpty)
                }
            }
        }
    }

    private func importPaste() {
        // Parse Showdown format — each Pokemon entry starts with a name line
        // Format: "PokemonName @ Item" or just "PokemonName"
        let lines = pasteText.components(separatedBy: .newlines)
        for line in lines {
            let rawName = line.components(separatedBy: "@").first?
                .trimmingCharacters(in: .whitespaces)
                .lowercased()
                .replacingOccurrences(of: " ", with: "-") ?? ""
            if let match = allPokemon.first(where: { $0.name == rawName }) {
                _ = team.addPokemon(id: match.id)
            }
        }
        try? context.save()
    }
}

// MARK: - Flow Layout (wrapping HStack for type badges)

struct FlowLayout<Content: View>: View {
    let spacing: CGFloat
    @ViewBuilder let content: () -> Content

    var body: some View {
        // Simple wrapping layout using ViewThatFits fallback approach
        // For iOS 16+ we can use Layout protocol; here we use a simpler approach
        _FlowLayout(spacing: spacing, content: content)
    }
}

private struct _FlowLayout<Content: View>: View {
    let spacing: CGFloat
    @ViewBuilder let content: () -> Content

    var body: some View {
        // Wrap in a scrollable HStack for simplicity — full flow layout would require custom Layout
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: spacing) { content() }
        }
    }
}
