import Foundation

protocol OpenAIRequest: Encodable {
  var path: String { get }
}

public struct OpenAIClient {
  private let endpoint: URL = .init(string: "https://api.openai.com/v1/")!

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
  
  public struct ChatRequest: OpenAIRequest {
    public struct Message: Encodable {
      public let role = "user"
      public let content: String
    }
    
    let model = "gpt-3.5-turbo"
    let messages: [Message]
    
    let temperature: CGFloat
    
    var path: String {
      "chat/completions"
    }

    public init(content: String, temperature: CGFloat) {
      self.messages = [.init(content: content)]
      self.temperature = temperature
    }
  }
  
  public enum Prompt {
    case correct(input: String)
    case shorten(input: String)
    case emphasize(input: String)
    case addTags(input: String)
    case insertTags(input: String)

    var request: OpenAIRequest {
      switch self {
      case let .correct(input):
        return ChatRequest(content: "Fix the spelling and grammar mistakes in the following text: \(input)", temperature: 0.2)
      case let .addTags(input):
        return ChatRequest(content: "Replace relevant words with Twitter hashtags in the following text while keeping the input same. Maximum of 5 hashtags: \(input)", temperature: 0.1)
      case let .insertTags(input):
        return ChatRequest(content: "Return the input with added Twitter hashtags at the end of the input with a maximum of 5 hashtags: \(input)", temperature: 0.2)
      case let .shorten(input):
        return ChatRequest(content: "Make a shorter version of this text: \(input)", temperature: 0.5)
      case let .emphasize(input):
        return ChatRequest(content: "Make this text catchy, more fun: \(input)", temperature: 1)
      }
    }
  }

  public struct Response: Decodable {
    public struct Choice: Decodable {
      public struct Message: Decodable {
        public let role: String
        public let content: String
      }
      
      public let message: Message?
    }

    public let choices: [Choice]

    public var trimmedText: String {
      guard var text = choices.first?.message?.content else {
        return ""
      }
      while text.first?.isNewline == true || text.first?.isWhitespace == true {
        text.removeFirst()
      }
      return text
    }
  }

  public init() {}

  public func request(_ prompt: Prompt) async throws -> Response {
    do {
      let jsonData = try encoder.encode(prompt.request)
      var request = URLRequest(url: endpoint.appending(path: prompt.request.path))
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

extension OpenAIClient: Sendable {}
extension OpenAIClient.Prompt: Sendable {}
extension OpenAIClient.ChatRequest: Sendable {}
extension OpenAIClient.ChatRequest.Message: Sendable {}
extension OpenAIClient.Response: Sendable {}
extension OpenAIClient.Response.Choice: Sendable {}
extension OpenAIClient.Response.Choice.Message: Sendable {}
