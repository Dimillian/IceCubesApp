import Foundation

public struct OpenAIClient {
  private let endpoint: URL = .init(string: "https://api.openai.com/v1/completions")!

  private var APIKey: String {
    if let path = Bundle.main.path(forResource: "Secret", ofType: "plist") {
      let secret = NSDictionary(contentsOfFile: path)
      return secret?["OPENAI_SECRET"] as? String ?? ""
    }
    return ""
  }

  private var authorizationHeaderValue: String {
    "Bearer \(APIKey)"
  }

  private var encoder: JSONEncoder {
    let encoder = JSONEncoder()
    encoder.keyEncodingStrategy = .convertToSnakeCase
    return encoder
  }

  private var decoder: JSONDecoder {
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    return decoder
  }

  public struct Request: Encodable {
    let model = "text-davinci-003"
    let topP: Int = 1
    let frequencyPenalty: Int = 0
    let presencePenalty: Int = 0
    let prompt: String
    let temperature: Double
    let maxTokens: Int

    public init(prompt: String, temperature: Double, maxTokens: Int) {
      self.prompt = prompt
      self.temperature = temperature
      self.maxTokens = maxTokens
    }
  }

  public enum Prompts {
    case correct(input: String)
    case shorten(input: String)
    case emphasize(input: String)

    var request: Request {
      switch self {
      case let .correct(input):
        return Request(prompt: "Correct this to standard English:\(input)",
                       temperature: 0,
                       maxTokens: 500)
      case let .shorten(input):
        return Request(prompt: "Make a summary of this paragraph:\(input)",
                       temperature: 0.7,
                       maxTokens: 100)
      case let .emphasize(input):
        return Request(prompt: "Make this paragraph catchy, more fun:\(input)",
                       temperature: 0.8,
                       maxTokens: 500)
      }
    }
  }

  public struct Response: Decodable {
    public struct Choice: Decodable {
      public let text: String
    }

    public let id: String
    public let object: String
    public let model: String
    public let choices: [Choice]

    public var trimmedText: String {
      guard var text = choices.first?.text else {
        return ""
      }
      while text.first?.isNewline == true || text.first?.isWhitespace == true {
        text.removeFirst()
      }
      return text
    }
  }

  public init() {}

  public func request(_ prompt: Prompts) async throws -> Response {
    do {
      let jsonData = try encoder.encode(prompt.request)
      var request = URLRequest(url: endpoint)
      request.httpMethod = "POST"
      request.setValue(authorizationHeaderValue, forHTTPHeaderField: "Authorization")
      request.setValue("application/json", forHTTPHeaderField: "Content-Type")
      request.httpBody = jsonData
      let (result, _) = try await URLSession.shared.data(for: request)
      let response = try decoder.decode(Response.self, from: result)
      return response
    } catch {
      throw error
    }
  }
}
