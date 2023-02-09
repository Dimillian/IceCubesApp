import Foundation

public struct MediaAttachment: Codable, Identifiable, Hashable, Equatable {
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
  
  public static func placeholders() -> [MediaAttachment] {
    var array = [MediaAttachment]()
    if let fileURL = Bundle.main.url(forResource: "public-domain-ice-cubes", withExtension: "jpg") {
      let picture1 = MediaAttachment(id: "pic1", type: "image", url: fileURL, previewUrl: nil, description: nil, meta: MetaContainer(original: MetaContainer.Meta(width: 850, height: 567)))
      array.append(picture1)
    }
    if let fileURL = Bundle.main.url(forResource: "public-domain-whiskey", withExtension: "jpg") {
      let picture2 = MediaAttachment(id: "pic1", type: "image", url: fileURL, previewUrl: nil, description: nil, meta: MetaContainer(original: MetaContainer.Meta(width: 850, height: 567)))
      array.append(picture2)
    }

    
    return array
  }
}
