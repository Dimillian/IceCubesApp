import AppAccount
import AppIntents
import Env
import Foundation
import Models
import Network
import Timeline

public struct ListEntity: Identifiable, AppEntity {
  public var id: String { list.id }

  public let list: Models.List

  public static let defaultQuery = DefaultListEntityQuery()

  public static let typeDisplayRepresentation: TypeDisplayRepresentation = "List"

  public var displayRepresentation: DisplayRepresentation {
    DisplayRepresentation(title: "\(list.title)")
  }
}

public struct DefaultListEntityQuery: EntityQuery {
  public init() {}
  
  @IntentParameterDependency<ListsWidgetConfiguration>(
    \.$account
  )
  var account
  
  public func entities(for _: [ListEntity.ID]) async throws -> [ListEntity] {
    await fetchLists().map{ .init(list: $0 )}
  }

  public func suggestedEntities() async throws -> [ListEntity] {
    await fetchLists().map{ .init(list: $0 )}
  }

  public func defaultResult() async -> ListEntity? {
    nil
  }
  
  private func fetchLists() async -> [Models.List] {
    guard let account = account?.account.account else {
      return []
    }
    let client = Client(server: account.server, oauthToken: account.oauthToken)
    do {
      let lists: [Models.List] = try await client.get(endpoint: Lists.lists)
      return lists
    } catch {
      return []
    }
  }
}
