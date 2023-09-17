import Models
import Network
import Observation
import SwiftUI

@MainActor
@Observable class EditAccountViewModel {
  @Observable class FieldEditViewModel: Identifiable {
    let id = UUID().uuidString
    var name: String = ""
    var value: String = ""

    init(name: String, value: String) {
      self.name = name
      self.value = value
    }
  }

  public var client: Client?

  var displayName: String = ""
  var note: String = ""
  var postPrivacy = Models.Visibility.pub
  var isSensitive: Bool = false
  var isBot: Bool = false
  var isLocked: Bool = false
  var isDiscoverable: Bool = false
  var fields: [FieldEditViewModel] = []

  var isLoading: Bool = true
  var isSaving: Bool = false
  var saveError: Bool = false

  init() {}

  func fetchAccount() async {
    guard let client else { return }
    do {
      let account: Account = try await client.get(endpoint: Accounts.verifyCredentials)
      displayName = account.displayName ?? ""
      note = account.source?.note ?? ""
      postPrivacy = account.source?.privacy ?? .pub
      isSensitive = account.source?.sensitive ?? false
      isBot = account.bot
      isLocked = account.locked
      isDiscoverable = account.discoverable ?? false
      fields = account.source?.fields.map { .init(name: $0.name, value: $0.value.asRawText) } ?? []
      withAnimation {
        isLoading = false
      }
    } catch {}
  }

  func save() async {
    isSaving = true
    do {
      let data = UpdateCredentialsData(displayName: displayName,
                                       note: note,
                                       source: .init(privacy: postPrivacy, sensitive: isSensitive),
                                       bot: isBot,
                                       locked: isLocked,
                                       discoverable: isDiscoverable,
                                       fieldsAttributes: fields.map { .init(name: $0.name, value: $0.value) })
      let response = try await client?.patch(endpoint: Accounts.updateCredentials(json: data))
      if response?.statusCode != 200 {
        saveError = true
      }
      isSaving = false
    } catch {
      isSaving = false
      saveError = true
    }
  }
}
