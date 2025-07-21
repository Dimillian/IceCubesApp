import Foundation

public struct NodeInfo: Codable, Sendable {
  public struct Software: Codable, Sendable {
    public let name: String
    public let version: String
  }
  
  public struct Usage: Codable, Sendable {
    public struct Users: Codable, Sendable {
      public let total: Int?
      public let activeMonth: Int?
      public let activeHalfyear: Int?
    }
    
    public let users: Users?
    public let localPosts: Int?
  }
  
  public let version: String
  public let software: Software
  public let protocols: [String]
  public let usage: Usage?
  public let openRegistrations: Bool
  public let metadata: [String: AnyCodable]?
}

// Helper for dynamic JSON values
public struct AnyCodable: Codable, Sendable {
  public let value: Any
  
  public init<T>(_ value: T?) {
    self.value = value ?? ()
  }
}

extension AnyCodable {
  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    
    if container.decodeNil() {
      self.init(())
    } else if let bool = try? container.decode(Bool.self) {
      self.init(bool)
    } else if let int = try? container.decode(Int.self) {
      self.init(int)
    } else if let double = try? container.decode(Double.self) {
      self.init(double)
    } else if let string = try? container.decode(String.self) {
      self.init(string)
    } else if let array = try? container.decode([AnyCodable].self) {
      self.init(array.map { $0.value })
    } else if let dictionary = try? container.decode([String: AnyCodable].self) {
      self.init(dictionary.mapValues { $0.value })
    } else {
      throw DecodingError.dataCorruptedError(in: container, debugDescription: "AnyCodable value cannot be decoded")
    }
  }
  
  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    
    switch value {
    case is Void:
      try container.encodeNil()
    case let bool as Bool:
      try container.encode(bool)
    case let int as Int:
      try container.encode(int)
    case let double as Double:
      try container.encode(double)
    case let string as String:
      try container.encode(string)
    case let array as [Any]:
      try container.encode(array.map { AnyCodable($0) })
    case let dictionary as [String: Any]:
      try container.encode(dictionary.mapValues { AnyCodable($0) })
    default:
      let context = EncodingError.Context(codingPath: container.codingPath, debugDescription: "AnyCodable value cannot be encoded")
      throw EncodingError.invalidValue(value, context)
    }
  }
}