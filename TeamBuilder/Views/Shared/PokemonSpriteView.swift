import SwiftUI

/// Loads and displays a Pokemon sprite from a URL.
/// Shows a Pokeball placeholder while loading.
struct PokemonSpriteView: View {
    let url: String?
    var size: CGFloat = 80

    var body: some View {
        AsyncImage(url: url.flatMap { URL(string: $0) }) { phase in
            switch phase {
            case .empty:
                Image(systemName: "circle.circle")
                    .resizable()
                    .foregroundStyle(.secondary.opacity(0.3))
                    .frame(width: size, height: size)
            case .success(let image):
                image
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
                    .frame(width: size, height: size)
            case .failure:
                Image(systemName: "questionmark.square.dashed")
                    .resizable()
                    .foregroundStyle(.secondary)
                    .frame(width: size, height: size)
            @unknown default:
                EmptyView()
            }
        }
    }
}
