import SwiftUI
import Models
import Network

@MainActor
class EditAccountViewModel: ObservableObject {
  public var client: Client?
  
  @Published var displayName: String = ""
  @Published var note: String = ""
  @Published var postPrivacy = Models.Visibility.pub
  @Published var isSensitive: Bool = false
  @Published var isBot: Bool = false
  @Published var isLocked: Bool = false
  @Published var isDiscoverable: Bool = false
  
  @Published var isLoading: Bool = true
  @Published var isSaving: Bool = false
  @Published var saveError: Bool = false
  
  init() { }
  
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
      withAnimation {
        isLoading = false
      }
    } catch { }
  }
  
  func save() async {
    isSaving = true
    do {
      let response =
      try await client?.patch(endpoint: Accounts.updateCredentials(displayName: displayName,
                                                                   note: note,
                                                                   privacy: postPrivacy,
                                                                   isSensitive: isSensitive,
                                                                   isBot: isBot,
                                                                   isLocked: isLocked,
                                                                   isDiscoverable: isDiscoverable))
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
