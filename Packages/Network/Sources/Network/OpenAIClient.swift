import Foundation

protocol OpenAIRequest: Encodable {
  var model: String { get }
}

public struct OpenAIClient {
  private let endpoint: URL = .init(string: "https://icecubesrelay.fly.dev/openai")!

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

    public init(content: String, temperature: CGFloat) {
      messages = [.init(content: content)]
      self.temperature = temperature
    }
  }

  public struct VisionRequest: OpenAIRequest {
    public struct Message: Encodable {
      public struct MessageContent: Encodable {
        public struct ImageUrl: Encodable {
          public let url: URL
        }

        public let type: String
        public let text: String?
        public let imageUrl: ImageUrl?
      }

      public let role = "user"
      public let content: [MessageContent]
    }

    let model = "gpt-4-vision-preview"
    let messages: [Message]
    let maxTokens = 50
  }

  public enum Prompt {
    case correct(input: String)
    case shorten(input: String)
    case emphasize(input: String)
    case addTags(input: String)
    case insertTags(input: String)
    case imageDescription(image: URL)

    var request: OpenAIRequest {
      switch self {
      case let .correct(input):
        ChatRequest(content: "Fix the spelling and grammar mistakes in the following text: \(input)", temperature: 0.2)
      case let .addTags(input):
        ChatRequest(content: "Replace relevant words with camel-cased hashtags in the following text. Don't try to search for context or add hashtags if there is not enough context: \(input)", temperature: 0.1)
      case let .insertTags(input):
        ChatRequest(content: "Return the input with added camel-cased hashtags at the end of the input. Don't try to search for context or add hashtags if there is not enough context: \(input)", temperature: 0.2)
      case let .shorten(input):
        ChatRequest(content: "Make a shorter version of this text: \(input)", temperature: 0.5)
      case let .emphasize(input):
        ChatRequest(content: "Make this text catchy, more fun: \(input)", temperature: 1)
      case let .imageDescription(image):
        VisionRequest(messages: [.init(content: [.init(type: "text", text: "What’s in this image? Be brief, it's for image alt description on a social network. Don't write in the first person.", imageUrl: nil),
                                                 .init(type: "image_url", text: nil, imageUrl: .init(url: image))])])
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
      var request = URLRequest(url: endpoint)
      request.httpMethod = "POST"
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
