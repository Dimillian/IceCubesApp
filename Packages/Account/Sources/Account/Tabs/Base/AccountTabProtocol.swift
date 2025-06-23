import SwiftUI
import Models
import Network
import StatusKit
import Env

public protocol AccountTabProtocol: Identifiable, Hashable {
  var id: String { get }
  var iconName: String { get }
  var accessibilityLabel: LocalizedStringKey { get }
  var isAvailableForCurrentUser: Bool { get }
  var isAvailableForOtherUsers: Bool { get }
  
  @MainActor func createFetcher(accountId: String, client: Client, isCurrentUser: Bool) -> any StatusesFetcher
  @MainActor func makeView(fetcher: any StatusesFetcher, client: Client, routerPath: RouterPath, account: Account?) -> AnyView
}

extension AccountTabProtocol {
  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.id == rhs.id
  }
  
  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}