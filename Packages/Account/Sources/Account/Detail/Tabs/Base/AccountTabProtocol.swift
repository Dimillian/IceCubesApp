import Env
import Models
import NetworkClient
import StatusKit
import SwiftUI

public protocol AccountTabProtocol: Identifiable, Hashable {
  associatedtype TabView: View

  var id: String { get }
  var iconName: String { get }
  var accessibilityLabel: LocalizedStringKey { get }
  var isAvailableForCurrentUser: Bool { get }
  var isAvailableForOtherUsers: Bool { get }

  @MainActor func createFetcher(accountId: String, client: MastodonClient, isCurrentUser: Bool)
    -> any StatusesFetcher
  @MainActor @ViewBuilder func makeView(
    fetcher: any StatusesFetcher, client: MastodonClient, routerPath: RouterPath, account: Account?
  ) -> TabView
}

extension AccountTabProtocol {
  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.id == rhs.id
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}
