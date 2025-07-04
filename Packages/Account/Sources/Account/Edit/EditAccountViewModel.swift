import Models
import NetworkClient
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

  public var client: MastodonClient?

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

  var isLoading: Bool = true
  var isSaving: Bool = false
  var saveError: Bool = false

  var mediaPickers: [PhotosPickerItem] = [] {
    didSet {
      if let item = mediaPickers.first {
        Task {
          if isChangingAvatar {
            if let data = await getItemImageData(item: item, for: .avatar) {
              _ = await uploadAvatar(data: data)
            }
            isChangingAvatar = false
          } else if isChangingHeader {
            if let data = await getItemImageData(item: item, for: .header) {
              _ = await uploadHeader(data: data)
            }
            isChangingHeader = false
          }
          await fetchAccount()
          mediaPickers = []
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
      avatar = account.haveAvatar ? account.avatar : nil
      header = account.haveHeader ? account.header : nil
      fields = account.source?.fields.map { .init(name: $0.name, value: $0.value.asRawText) } ?? []
      withAnimation {
        isLoading = false
      }
    } catch {}
  }

  func save() async {
    isSaving = true
    do {
      let data = UpdateCredentialsData(
        displayName: displayName,
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

  func deleteAvatar() async -> Bool {
    guard let client else { return false }
    do {
      let response = try await client.delete(endpoint: Profile.deleteAvatar)
      avatar = nil
      return response?.statusCode == 200
    } catch {
      return false
    }
  }

  func deleteHeader() async -> Bool {
    guard let client else { return false }
    do {
      let response = try await client.delete(endpoint: Profile.deleteHeader)
      header = nil
      return response?.statusCode == 200
    } catch {
      return false
    }
  }

  private func uploadHeader(data: Data) async -> Bool {
    guard let client else { return false }
    do {
      let response = try await client.mediaUpload(
        endpoint: Accounts.updateCredentialsMedia,
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
      let response = try await client.mediaUpload(
        endpoint: Accounts.updateCredentialsMedia,
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

  private func getItemImageData(item: PhotosPickerItem, for type: ItemType) async -> Data? {
    guard
      let imageFile = try? await item.loadTransferable(
        type: StatusEditor.ImageFileTranseferable.self)
    else { return nil }

    let compressor = StatusEditor.Compressor()

    guard let compressedData = await compressor.compressImageFrom(url: imageFile.url),
      let image = UIImage(data: compressedData),
      let uploadData = try? await compressor.compressImageForUpload(
        image,
        maxSize: 2 * 1024 * 1024,  // 2MB
        maxHeight: type.maxHeight,
        maxWidth: type.maxWidth
      )
    else {
      return nil
    }

    return uploadData
  }
}

extension EditAccountViewModel {
  private enum ItemType {
    case avatar
    case header

    var maxHeight: CGFloat {
      switch self {
      case .avatar:
        400
      case .header:
        500
      }
    }

    var maxWidth: CGFloat {
      switch self {
      case .avatar:
        400
      case .header:
        1500
      }
    }
  }
}
