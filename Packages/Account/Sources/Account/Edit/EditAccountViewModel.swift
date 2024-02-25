import Models
import Network
import Observation
import PhotosUI
import StatusKit
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
  var avatar: URL?
  var header: URL?

  var isPhotoPickerPresented: Bool = false {
    didSet {
      if !isPhotoPickerPresented, mediaPickers.isEmpty {
        isChangingAvatar = false
        isChangingHeader = false
      }
    }
  }

  var isChangingAvatar: Bool = false
  var isChangingHeader: Bool = false
    
  // New images picked.
  // Store until profile saved.
  var temporaryAvatarData: Data?
  var temporaryHeaderData: Data?

  var isLoading: Bool = true
  var isSaving: Bool = false
  var saveError: Bool = false

  var mediaPickers: [PhotosPickerItem] = [] {
    didSet {
      if let item = mediaPickers.first {
        Task {
          if let data = await getItemImageData(item: item) {
            if isChangingAvatar {
              temporaryAvatarData = data
            } else if isChangingHeader {
              temporaryHeaderData = data
            }
            isChangingAvatar = false
            isChangingHeader = false
            mediaPickers = []
          }
        }
      }
    }
  }

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
      avatar = account.avatar
      header = account.header
      fields = account.source?.fields.map { .init(name: $0.name, value: $0.value.asRawText) } ?? []
      withAnimation {
        isLoading = false
      }
    } catch {}
  }

  func save() async {
    isSaving = true
    do {
      // Upload new images
      if let temporaryAvatarData {
        _ = await uploadAvatar(data: temporaryAvatarData)
      }
      if let temporaryHeaderData {
         _ = await uploadHeader(data: temporaryHeaderData)
      }
      // Clear preview data
      temporaryAvatarData = nil
      temporaryHeaderData = nil
      // Fetch account to set header and avatar
      await fetchAccount()
        
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

  private func uploadHeader(data: Data) async -> Bool {
    guard let client else { return false }
    do {
      let response = try await client.mediaUpload(endpoint: Accounts.updateCredentialsMedia,
                                                  version: .v1,
                                                  method: "PATCH",
                                                  mimeType: "image/jpeg",
                                                  filename: "header",
                                                  data: data)
      return response?.statusCode == 200
    } catch {
      return false
    }
  }

  private func uploadAvatar(data: Data) async -> Bool {
    guard let client else { return false }
    do {
      let response = try await client.mediaUpload(endpoint: Accounts.updateCredentialsMedia,
                                                  version: .v1,
                                                  method: "PATCH",
                                                  mimeType: "image/jpeg",
                                                  filename: "avatar",
                                                  data: data)
      return response?.statusCode == 200
    } catch {
      return false
    }
  }

  private func getItemImageData(item: PhotosPickerItem) async -> Data? {
    guard let imageFile = try? await item.loadTransferable(type: StatusEditor.ImageFileTranseferable.self) else { return nil }

    let compressor = StatusEditor.Compressor()

    guard let compressedData = await compressor.compressImageFrom(url: imageFile.url),
          let image = UIImage(data: compressedData),
          let uploadData = try? await compressor.compressImageForUpload(image)
    else { return nil }

    return uploadData
  }
}
