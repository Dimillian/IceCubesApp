import Foundation
import AppIntents
import AppAccount
import Network
import Env
import Models

enum PostVisibility: String, AppEnum {
  case direct, priv, unlisted, pub
  
  public static var caseDisplayRepresentations: [PostVisibility : DisplayRepresentation] {
    [.direct: "Private",
    .priv: "Followers Only",
    .unlisted: "Quiet Public",
    .pub: "Public"]
  }
  
  static var typeDisplayName: LocalizedStringResource {
    get { "Visibility" }
  }
  
  public static let typeDisplayRepresentation: TypeDisplayRepresentation = "Visibility"
  
  var toAppVisibility: Models.Visibility {
    switch self {
    case .direct:
        .direct
    case .priv:
        .priv
    case .unlisted:
        .unlisted
    case .pub:
        .pub
    }
  }
}

struct AppAccountWrapper: Identifiable, AppEntity {
  var id: String { account.id }
  
  let account: AppAccount
  
  static var defaultQuery = DefaultAppAccountQuery()
  
  static var typeDisplayRepresentation: TypeDisplayRepresentation = "AppAccount"
  
  var displayRepresentation: DisplayRepresentation {
    DisplayRepresentation(title: "\(account.accountName ?? account.server)")
  }
  
}

struct DefaultAppAccountQuery: EntityQuery {
  
  func entities(for identifiers: [AppAccountWrapper.ID]) async throws -> [AppAccountWrapper] {
    return await AppAccountsManager.shared.availableAccounts.filter { account in
      identifiers.contains { id in
        id == account.id
      }
    }.map{ AppAccountWrapper(account: $0 )}
  }

  func suggestedEntities() async throws -> [AppAccountWrapper] {
    await AppAccountsManager.shared.availableAccounts.map{ .init(account: $0)}
  }

  func defaultResult() async -> AppAccountWrapper? {
    await .init(account: AppAccountsManager.shared.currentAccount)
  }
}

struct InlinePostIntent: AppIntent {
  static let title: LocalizedStringResource = "Send text status to Mastodon"
  static var description: IntentDescription {
    get {
      "Send a text status to Mastodon using Ice Cubes"
    }
  }
  static let openAppWhenRun: Bool = false
  
  @Parameter(title: "Account", requestValueDialog: IntentDialog("Account"))
  var account: AppAccountWrapper
  
  @Parameter(title: "Post visibility", requestValueDialog: IntentDialog("Visibility of your post"))
  var visibility: PostVisibility
  
  @Parameter(title: "Post content", requestValueDialog: IntentDialog("Content of the post to be sent to Mastodon"))
  var content: String
  
  @MainActor
  func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
    let client = Client(server: account.account.server, version: .v1, oauthToken: account.account.oauthToken)
    let status = StatusData(status: content, visibility: visibility.toAppVisibility)
    do {
      let status: Status = try await client.post(endpoint: Statuses.postStatus(json: status))
      return .result(dialog: "\(status.content.asRawText) was posted on Mastodon")
    } catch {
      return .result(dialog: "An error occured while posting to Mastodon, please try again.")
    }
  }
}
