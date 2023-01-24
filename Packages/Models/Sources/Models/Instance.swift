import Foundation

public struct Instance: Codable {
  public struct Stats: Codable {
    public let userCount: Int
    public let statusCount: Int
    public let domainCount: Int
  }

  public struct Configuration: Codable {
    public struct Statuses: Codable {
      public let maxCharacters: Int
      public let maxMediaAttachments: Int
    }

    public struct Polls: Codable {
      public let maxOptions: Int
      public let maxCharactersPerOption: Int
      public let minExpiration: Int
      public let maxExpiration: Int
    }

    public let statuses: Statuses
    public let polls: Polls
  }

  public struct Rule: Codable, Identifiable {
    public let id: String
    public let text: String
  }
	
  public var title = ""
  public var shortDescription = ""
  public var email = ""
  public var version = ""
  public let stats: Stats
  public var languages = [String]()
  public let registrations: Bool
  public let thumbnail: URL?
  public var configuration: Configuration?
  public var rules = [Rule]()

  enum CodingKeys: String, CodingKey {
  	case title, shortDescription, email, version, stats, languages, registrations, thumbnail, configuration, rules
  }
	
  public init(from decoder: Decoder) throws {
  	do {
  	  let values = try decoder.container(keyedBy: CodingKeys.self)
  	  title = try values.decode(String.self, forKey: .title)
  	  if let txt = try? values.decode(String.self, forKey: .shortDescription) {
  	  	shortDescription =  txt
  	  }
  	  email = try values.decode(String.self, forKey: .email)
  	  version = try values.decode(String.self, forKey: .version)
  	  stats = try values.decode(Stats.self, forKey: .stats)
  	  languages = try values.decode([String].self, forKey: .languages)
  	  registrations = try values.decode(Bool.self, forKey: .registrations)
  	  thumbnail = try values.decode(URL.self, forKey: .thumbnail)
  	  if let cfg = try? values.decode(Configuration.self, forKey: .configuration) {
  	  	configuration = cfg
  	  }
  	  if let arr = try? values.decode([Rule].self, forKey: .rules) {
  	  	rules = arr
  	  }
  	} catch {
  	  NSLog("*** Error decoding Instance: \(error)")
  	  throw error
  	}
  }

}
