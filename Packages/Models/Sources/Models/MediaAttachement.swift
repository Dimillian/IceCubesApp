import Foundation

public struct MediaAttachement: Codable, Identifiable, Hashable {  
  public enum SupportedType: String {
    case image, gifv
  }
  
  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
  
  public let id: String
  public let type: String
  public var supportedType: SupportedType? {
    SupportedType(rawValue: type)
  }
  public let url: URL
  public let previewUrl: URL?
  public let description: String?
}

