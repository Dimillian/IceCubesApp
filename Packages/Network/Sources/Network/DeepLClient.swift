import Foundation

public struct DeepLClient {
  private let endpoint = "https://api.deepl.com/v2/translate"

  private var APIKey: String {
    if let path = Bundle.main.path(forResource: "Secret", ofType: "plist") {
      let secret = NSDictionary(contentsOfFile: path)
      return secret?["DEEPL_SECRET"] as? String ?? ""
    }
    return ""
  }

  private var authorizationHeaderValue: String {
    "DeepL-Auth-Key \(APIKey)"
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

  public init() {}

  public func request(target: String, source _: String?, text: String) async throws -> String {
    do {
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
      return response.translations.first?.text.removingPercentEncoding ?? ""
    } catch {
      throw error
    }
  }
}
