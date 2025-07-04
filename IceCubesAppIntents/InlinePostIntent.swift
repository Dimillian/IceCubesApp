import AppAccount
import AppIntents
import Env
import Foundation
import Models
import NetworkClient

enum PostVisibility: String, AppEnum {
  case direct, priv, unlisted, pub

  public static var caseDisplayRepresentations: [PostVisibility: DisplayRepresentation] {
    [
      .direct: "Private",
      .priv: "Followers Only",
      .unlisted: "Quiet Public",
      .pub: "Public",
    ]
  }

  static var typeDisplayName: LocalizedStringResource { "Visibility" }

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

struct InlinePostIntent: AppIntent {
  static let title: LocalizedStringResource = "Send post to Mastodon"
  static let description: IntentDescription = "Send a text post to Mastodon with Ice Cubes"
  static let openAppWhenRun: Bool = false

  @Parameter(title: "Account", requestValueDialog: IntentDialog("Account"))
  var account: AppAccountEntity

  @Parameter(title: "Post visibility", requestValueDialog: IntentDialog("Visibility of your post"))
  var visibility: PostVisibility

  @Parameter(
    title: "Post content",
    requestValueDialog: IntentDialog("Content of the post to be sent to Mastodon"))
  var content: String

  @MainActor
  func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
    let client = MastodonClient(
      server: account.account.server, version: .v1, oauthToken: account.account.oauthToken)
    let status = StatusData(status: content, visibility: visibility.toAppVisibility)
    do {
      let status: Status = try await client.post(endpoint: Statuses.postStatus(json: status))
      return .result(dialog: "\(status.content.asRawText) was posted on Mastodon")
    } catch {
      return .result(dialog: "An error occured while posting to Mastodon, please try again.")
    }
  }
}
