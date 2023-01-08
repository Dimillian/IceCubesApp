import Foundation

public struct MediaAttachement: Codable, Identifiable, Hashable {
  
  public struct MetaContainer: Codable, Equatable {
    public struct Meta: Codable, Equatable {
      public let width: Int?
      public let height: Int?
    }
    public let original: Meta?
  }
  
  public enum SupportedType: String {
    case image, gifv, video, audio
  }
  
  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
  
  public let id: String
  public let type: String
  public var supportedType: SupportedType? {
    SupportedType(rawValue: type)
  }
  public let url: URL?
  public let previewUrl: URL?
  public let description: String?
  public let meta: MetaContainer?
}

