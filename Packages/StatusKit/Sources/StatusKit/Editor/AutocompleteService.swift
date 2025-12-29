import Models
import NetworkClient

extension StatusEditor {
  @MainActor
  struct AutocompleteService {
    @MainActor
    protocol Client {
      func searchHashtags(query: String) async throws -> [Tag]
      func searchAccounts(query: String) async throws -> [Account]
    }

    enum Result: Equatable {
      case showRecentsTagsInline
      case tags([Tag])
      case mentions([Account])
      case none
    }

    func fetchSuggestions(for query: String, client: Client) async throws -> Result {
      guard let firstCharacter = query.first else { return .none }

      switch firstCharacter {
      case "#":
        if query.utf8.count == 1 {
          return .showRecentsTagsInline
        }
        let tags = try await client.searchHashtags(query: String(query.dropFirst()))
          .sorted(by: { $0.totalUses > $1.totalUses })
        return .tags(tags)
      case "@":
        guard query.utf8.count > 1 else { return .none }
        let accounts = try await client.searchAccounts(query: String(query.dropFirst()))
        return .mentions(accounts)
      default:
        return .none
      }
    }
  }
}

@MainActor
extension MastodonClient: StatusEditor.AutocompleteService.Client {
  public func searchHashtags(query: String) async throws -> [Tag] {
    let results: SearchResults = try await get(
      endpoint: Search.search(
        query: query,
        type: .hashtags,
        offset: 0,
        following: nil
      ),
      forceVersion: .v2
    )
    return results.hashtags
  }

  public func searchAccounts(query: String) async throws -> [Account] {
    try await get(
      endpoint: Search.accountsSearch(
        query: query,
        type: nil,
        offset: 0,
        following: nil
      ),
      forceVersion: .v1
    )
  }
}
