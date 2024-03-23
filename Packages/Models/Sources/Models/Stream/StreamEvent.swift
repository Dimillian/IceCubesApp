import Foundation

public struct RawStreamEvent: Decodable {
  public let event: String
  public let stream: [String]
  public let payload: String
}

public protocol StreamEvent: Identifiable {
  var date: Date { get }
  var id: String { get }
}

public struct StreamEventUpdate: StreamEvent {
  public let date = Date()
  public var id: String { status.id }
  public let status: Status
  public init(status: Status) {
    self.status = status
  }
}

public struct StreamEventStatusUpdate: StreamEvent {
  public let date = Date()
  public var id: String { status.id + (status.editedAt?.asDate.description ?? "") }
  public let status: Status
  public init(status: Status) {
    self.status = status
  }
}

public struct StreamEventDelete: StreamEvent {
  public let date = Date()
  public var id: String { status + date.description }
  public let status: String
  public init(status: String) {
    self.status = status
  }
}

public struct StreamEventNotification: StreamEvent {
  public let date = Date()
  public var id: String { notification.id }
  public let notification: Notification
  public init(notification: Notification) {
    self.notification = notification
  }
}

public struct StreamEventConversation: StreamEvent {
  public let date = Date()
  public var id: String { conversation.id }
  public let conversation: Conversation
  public init(conversation: Conversation) {
    self.conversation = conversation
  }
}
