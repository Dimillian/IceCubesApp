import Foundation

public struct MediaAttachement: Codable, Identifiable, Hashable {
  public struct Meta: Codable, Equatable {
    public let width: Int?
    public let height: Int?
    public let size: String?
    public let aspect: Float?
    public let x: Float?
    public let y: Float?
  }
  
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
  public let meta: [String: Meta]?
}

