import Foundation

/// Handles on-demand network calls to PokeAPI.
/// Pokemon data is now bundled locally — this actor is only used for
/// ability descriptions (fetched on-demand when the user taps to expand).
actor PokeAPIService {

    static let shared = PokeAPIService()
    private let baseURL = "https://pokeapi.co/api/v2"

    // MARK: - Ability description (fetched on demand)

    /// Returns the plain-English description for an ability name.
    func abilityDescription(name: String) async throws -> String {
        let url = URL(string: "\(baseURL)/ability/\(name)")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(AbilityResponse.self, from: data)
        return response.effectEntries
            .filter { $0.language.name == "en" }
            .last?.shortEffect ?? "No description available."
    }
}

// MARK: - Response model

private struct AbilityResponse: Decodable {
    let effectEntries: [EffectEntry]
    enum CodingKeys: String, CodingKey { case effectEntries = "effect_entries" }
    struct EffectEntry: Decodable {
        let shortEffect: String
        let language: NamedResource
        enum CodingKeys: String, CodingKey { case shortEffect = "short_effect"; case language }
    }
    struct NamedResource: Decodable { let name: String }
}
