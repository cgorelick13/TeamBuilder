import SwiftUI
import SwiftData

/// My Teams tab — list of all saved teams with score breakdowns, create/delete/duplicate.
struct MyTeamsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \PokemonTeam.createdAt) private var teams: [PokemonTeam]

    @State private var showNewTeamSheet = false
    @State private var teamToRename: PokemonTeam?

    var body: some View {
        NavigationStack {
            Group {
                if teams.isEmpty {
                    ContentUnavailableView(
                        "No Teams Yet",
                        systemImage: "person.3",
                        description: Text("Tap + to create your first team.")
                    )
                } else {
                    List {
                        ForEach(teams) { team in
                            NavigationLink(destination: TeamDetailView(team: team)) {
                                TeamRowView(team: team)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    context.delete(team)
                                    try? context.save()
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .leading) {
                                Button {
                                    let copy = team.duplicate(newName: "\(team.name) Copy")
                                    context.insert(copy)
                                    try? context.save()
                                } label: {
                                    Label("Duplicate", systemImage: "doc.on.doc")
                                }
                                .tint(.blue)

                                Button {
                                    // Toggle active status — deactivate all others first
                                    for t in teams { t.isActive = false }
                                    team.isActive = true
                                    try? context.save()
                                } label: {
                                    Label(team.isActive ? "Active" : "Set Active", systemImage: "star.fill")
                                }
                                .tint(.yellow)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("My Teams")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showNewTeamSheet = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showNewTeamSheet) {
                NewTeamSheet()
            }
        }
    }
}

// MARK: - Team Row

struct TeamRowView: View {
    let team: PokemonTeam
    @Query private var allPokemon: [CachedPokemon]

    private var teamPokemon: [CachedPokemon] {
        team.pokemonIDs.compactMap { id in allPokemon.first { $0.id == id } }
    }

    private var scoreResult: TeamScorer.ScoreResult {
        TeamScorer.score(team: teamPokemon)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if team.isActive {
                    Image(systemName: "star.fill").foregroundStyle(.yellow).font(.caption)
                }
                Text(team.name).font(.headline)
                Spacer()
                FormatTag(tag: team.formatTag)
            }

            // 6 sprite slots
            HStack(spacing: 4) {
                ForEach(0..<6, id: \.self) { index in
                    if index < teamPokemon.count {
                        PokemonSpriteView(url: teamPokemon[index].spriteURL, size: 36)
                    } else {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(.tertiarySystemFill))
                            .frame(width: 36, height: 36)
                    }
                }
                Spacer()
                // Score with sub-scores
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(scoreResult.total)")
                        .font(.title2.bold())
                        .foregroundStyle(scoreColor(scoreResult.total))
                    Text("Cov:\(scoreResult.coverage) Def:\(scoreResult.defense) Sta:\(scoreResult.stats)")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func scoreColor(_ score: Int) -> Color {
        switch score {
        case 80...100: return .green
        case 60...79:  return .yellow
        default:       return .red
        }
    }
}

// MARK: - Format Tag Chip

struct FormatTag: View {
    let tag: String
    var body: some View {
        Text(tag)
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(.blue.opacity(0.8), in: Capsule())
    }
}

// MARK: - New Team Sheet

struct NewTeamSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @State private var name = ""
    @State private var format = "Casual"

    var body: some View {
        NavigationStack {
            Form {
                Section("Team Name") {
                    TextField("e.g. My Dream Team", text: $name)
                }
                Section("Format") {
                    Picker("Format", selection: $format) {
                        ForEach(TeamFormat.allCases, id: \.rawValue) {
                            Text($0.rawValue).tag($0.rawValue)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
            .navigationTitle("New Team")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        let team = PokemonTeam(name: name.isEmpty ? "New Team" : name, formatTag: format)
                        context.insert(team)
                        try? context.save()
                        dismiss()
                    }
                }
            }
        }
    }
}
