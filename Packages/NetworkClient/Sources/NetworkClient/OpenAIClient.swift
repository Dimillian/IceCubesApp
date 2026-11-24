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

    let model = "gpt-4o-mini"
    let messages: [Message]
    let maxTokens = 150
  }

  public enum Prompt {
    case imageDescription(image: URL, languageCode: String?)

    var request: OpenAIRequest {
      switch self {
      case let .imageDescription(image, languageCode):
        VisionRequest(messages: [
          .init(content: [
            .init(
              type: "text",
              text: Self.imageDescriptionText(languageCode: languageCode),
              imageUrl: nil),
            .init(type: "image_url", text: nil, imageUrl: .init(url: image)),
          ])
        ])
      }
    }

    static func imageDescriptionText(languageCode: String?) -> String {
      var text =
        "What’s in this image? Be brief, it's for image alt description on a social network. Don't write in the first person."
      if let languageCode,
        let language = Locale(identifier: "en").localizedString(forLanguageCode: languageCode)
      {
        text += " Write the description in \(language)."
      }
      return text
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
extension OpenAIClient.Response: Sendable {}
extension OpenAIClient.Response.Choice: Sendable {}
extension OpenAIClient.Response.Choice.Message: Sendable {}
