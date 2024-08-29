import Foundation
import Models

public struct DeepLClient: Sendable {
  public enum DeepLError: Error {
    case notFound
  }

  private var deeplUserAPIKey: String?
  private var deeplUserAPIFree: Bool
  private var endpoint: String {
    "https://api\(deeplUserAPIFree && (deeplUserAPIKey != nil) ? "-free" : "").deepl.com/v2/translate"
  }

  private var authorizationHeaderValue: String {
    "DeepL-Auth-Key \(deeplUserAPIKey ?? "")"
  }

  public struct Response: Decodable {
    public struct Translation: Decodable {
      public let detectedSourceLanguage: String
      public let text: String
    }

    public let translations: [Translation]
  }

  private var decoder: JSONDecoder {
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    return decoder
  }

  public init(userAPIKey: String?, userAPIFree: Bool) {
    deeplUserAPIKey = userAPIKey
    deeplUserAPIFree = userAPIFree
  }

  public func request(target: String, text: String) async throws -> Translation {
    var components = URLComponents(string: endpoint)!
    var queryItems: [URLQueryItem] = []
    queryItems.append(.init(name: "text", value: text))
    queryItems.append(.init(name: "target_lang", value: target.uppercased()))
    components.queryItems = queryItems
    var request = URLRequest(url: components.url!)
    request.httpMethod = "POST"
    request.setValue(authorizationHeaderValue, forHTTPHeaderField: "Authorization")
    request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
    let (result, _) = try await URLSession.shared.data(for: request)
    let response = try decoder.decode(Response.self, from: result)
    if let translation = response.translations.first {
      return .init(content: translation.text.removingPercentEncoding ?? "",
                   detectedSourceLanguage: translation.detectedSourceLanguage,
                   provider: "DeepL.com")
    }
    throw DeepLError.notFound
  }
}
