import AppAccount
import AppIntents
import Env
import Foundation
import Models
import Network

extension IntentDescription: @unchecked Sendable {}
extension TypeDisplayRepresentation: @unchecked Sendable {}

public struct AppAccountEntity: Identifiable, AppEntity {
  public var id: String { account.id }

  public let account: AppAccount

  public static let defaultQuery = DefaultAppAccountEntityQuery()

  public static let typeDisplayRepresentation: TypeDisplayRepresentation = "AppAccount"

  public var displayRepresentation: DisplayRepresentation {
    DisplayRepresentation(title: "\(account.accountName ?? account.server)")
  }
}

public struct DefaultAppAccountEntityQuery: EntityQuery {
  public init() {}

  public func entities(for identifiers: [AppAccountEntity.ID]) async throws -> [AppAccountEntity] {
    return await AppAccountsManager.shared.availableAccounts.filter { account in
      identifiers.contains { id in
        id == account.id
      }
    }.map { AppAccountEntity(account: $0) }
  }

  public func suggestedEntities() async throws -> [AppAccountEntity] {
    await AppAccountsManager.shared.availableAccounts.map { .init(account: $0) }
  }

  public func defaultResult() async -> AppAccountEntity? {
    await .init(account: AppAccountsManager.shared.currentAccount)
  }
}
