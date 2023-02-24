import Models
import Network
import SwiftUI

@MainActor
class EditAccountViewModel: ObservableObject {
  
  class FieldEditViewModel: ObservableObject, Identifiable {
    let id = UUID().uuidString
    @Published var name: String = ""
    @Published var value: String = ""
    
    init(name: String, value: String) {
      self.name = name
      self.value = value
    }
  }
  
  public var client: Client?

  @Published var displayName: String = ""
  @Published var note: String = ""
  @Published var postPrivacy = Models.Visibility.pub
  @Published var isSensitive: Bool = false
  @Published var isBot: Bool = false
  @Published var isLocked: Bool = false
  @Published var isDiscoverable: Bool = false
  @Published var fields: [FieldEditViewModel] = []

  @Published var isLoading: Bool = true
  @Published var isSaving: Bool = false
  @Published var saveError: Bool = false

  init() {}

  func fetchAccount() async {
    guard let client else { return }
    do {
      let account: Account = try await client.get(endpoint: Accounts.verifyCredentials)
      displayName = account.displayName
      note = account.source?.note ?? ""
      postPrivacy = account.source?.privacy ?? .pub
      isSensitive = account.source?.sensitive ?? false
      isBot = account.bot
      isLocked = account.locked
      isDiscoverable = account.discoverable ?? false
      fields = account.fields.map{ .init(name: $0.name, value: $0.value.asRawText )}
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
                                       fieldsAttributes: fields.map{ .init(name: $0.name, value: $0.value)})
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
