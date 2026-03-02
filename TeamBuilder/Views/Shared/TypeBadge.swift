import SwiftUI

/// A small colored badge showing a Pokemon type (e.g. "Fire", "Water")
struct TypeBadge: View {
    let typeName: String

    private var pokemonType: PokemonType? { PokemonType(rawValue: typeName) }

    var body: some View {
        Text(typeName.capitalized)
            .font(.caption.bold())
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(pokemonType?.color ?? .gray, in: Capsule())
    }
}

/// Horizontal row of type badges for a Pokemon
struct TypeBadgeRow: View {
    let types: [String]

    var body: some View {
        HStack(spacing: 6) {
            ForEach(types, id: \.self) { TypeBadge(typeName: $0) }
        }
    }
}
