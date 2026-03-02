import SwiftUI

/// Loads and displays a Pokemon sprite from a URL.
/// Shows a Pokeball placeholder while loading, retries once on failure.
struct PokemonSpriteView: View {
    let url: String?
    var size: CGFloat = 80

    @State private var retryID = 0

    var body: some View {
        AsyncImage(url: url.flatMap { URL(string: $0) }, transaction: Transaction(animation: .none)) { phase in
            switch phase {
            case .empty:
                Image(systemName: "circle.circle")
                    .resizable()
                    .foregroundStyle(.secondary.opacity(0.3))
                    .frame(width: size, height: size)
            case .success(let image):
                image
                    .resizable()
                    .scaledToFit()
                    .frame(width: size, height: size)
            case .failure:
                // Tap the placeholder to retry loading
                Button {
                    retryID += 1
                } label: {
                    Image(systemName: "arrow.clockwise.circle")
                        .resizable()
                        .foregroundStyle(.secondary.opacity(0.4))
                        .frame(width: size * 0.6, height: size * 0.6)
                        .frame(width: size, height: size)
                }
                .buttonStyle(.plain)
            @unknown default:
                EmptyView()
            }
        }
        .id("\(url ?? "")-\(retryID)")
    }
}
