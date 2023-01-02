import SwiftUI
import Timeline
import Account
import Env
import Status
import DesignSystem
import Lists

extension View {
  func withAppRouteur() -> some View {
    self.navigationDestination(for: RouteurDestinations.self) { destination in
      switch destination {
      case let .accountDetail(id):
        AccountDetailView(accountId: id)
      case let .accountDetailWithAccount(account):
        AccountDetailView(account: account)
      case let .statusDetail(id):
        StatusDetailView(statusId: id)
      case let .hashTag(tag, accountId):
        TimelineView(timeline: .constant(.hashtag(tag: tag, accountId: accountId)), scrollToTopSignal: .constant(0))
      case let .list(list):
        TimelineView(timeline: .constant(.list(list: list)), scrollToTopSignal: .constant(0))
      case let .following(id):
        AccountsListView(mode: .following(accountId: id))
      case let .followers(id):
        AccountsListView(mode: .followers(accountId: id))
      case let .favouritedBy(id):
        AccountsListView(mode: .favouritedBy(statusId: id))
      case let .rebloggedBy(id):
        AccountsListView(mode: .rebloggedBy(statusId: id))
      }
    }
  }
  
  func withSheetDestinations(sheetDestinations: Binding<SheetDestinations?>) -> some View {
    self.sheet(item: sheetDestinations) { destination in
      switch destination {
      case let .replyToStatusEditor(status):
        StatusEditorView(mode: .replyTo(status: status))
      case .newStatusEditor:
        StatusEditorView(mode: .new)
      case let .editStatusEditor(status):
        StatusEditorView(mode: .edit(status: status))
      case let .quoteStatusEditor(status):
        StatusEditorView(mode: .quote(status: status))
      case let .listEdit(list):
        ListEditView(list: list)
      case let .listAddAccount(account):
        ListAddAccountView(account: account)
      }
    }
  }
}
