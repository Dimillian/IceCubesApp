import Combine
import Foundation
import Models
import Network
import Observation

@MainActor
@Observable public class StreamWatcher {
  private var client: Client?
  private var task: URLSessionWebSocketTask?
  private var watchedStreams: [Stream] = []
  private var instanceStreamingURL: URL?

  private let decoder = JSONDecoder()
  private let encoder = JSONEncoder()

  private var retryDelay: Int = 10

  public enum Stream: String {
    case publicTimeline = "public"
    case user
    case direct
  }

  public var events: [any StreamEvent] = []
  public var unreadNotificationsCount: Int = 0
  public var latestEvent: (any StreamEvent)?

  public init() {
    decoder.keyDecodingStrategy = .convertFromSnakeCase
  }

  public func setClient(client: Client, instanceStreamingURL: URL?) {
    if self.client != nil {
      stopWatching()
    }
    self.client = client
    self.instanceStreamingURL = instanceStreamingURL
    connect()
  }

  private func connect() {
    guard let task = try? client?.makeWebSocketTask(
      endpoint: Streaming.streaming,
      instanceStreamingURL: instanceStreamingURL
    ) else {
      return
    }
    self.task = task
    self.task?.resume()
    receiveMessage()
  }

  public func watch(streams: [Stream]) {
    if client?.isAuth == false {
      return
    }
    if task == nil {
      connect()
    }
    watchedStreams = streams
    streams.forEach { stream in
      sendMessage(message: StreamMessage(type: "subscribe", stream: stream.rawValue))
    }
  }

  public func stopWatching() {
    task?.cancel()
    task = nil
  }

  private func sendMessage(message: StreamMessage) {
    if let encodedMessage = try? encoder.encode(message),
       let stringMessage = String(data: encodedMessage, encoding: .utf8)
    {
      task?.send(.string(stringMessage), completionHandler: { _ in })
    }
  }

  private func receiveMessage() {
    task?.receive(completionHandler: { [weak self] result in
      guard let self else { return }
      switch result {
      case let .success(message):
        switch message {
        case let .string(string):
          do {
            guard let data = string.data(using: .utf8) else {
              print("Error decoding streaming event string")
              return
            }
            let rawEvent = try decoder.decode(RawStreamEvent.self, from: data)
            if let event = rawEventToEvent(rawEvent: rawEvent) {
              Task { @MainActor in
                self.events.append(event)
                self.latestEvent = event
                if let event = event as? StreamEventNotification, event.notification.status?.visibility != .direct {
                  self.unreadNotificationsCount += 1
                }
              }
            }
          } catch {
            print("Error decoding streaming event: \(error.localizedDescription)")
          }

        default:
          break
        }

        receiveMessage()

      case .failure:
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(retryDelay)) {
          self.retryDelay += 30
          self.stopWatching()
          self.connect()
          self.watch(streams: self.watchedStreams)
        }
      }
    })
  }

  private func rawEventToEvent(rawEvent: RawStreamEvent) -> (any StreamEvent)? {
    guard let payloadData = rawEvent.payload.data(using: .utf8) else {
      return nil
    }
    do {
      switch rawEvent.event {
      case "update":
        let status = try decoder.decode(Status.self, from: payloadData)
        return StreamEventUpdate(status: status)
      case "status.update":
        let status = try decoder.decode(Status.self, from: payloadData)
        return StreamEventStatusUpdate(status: status)
      case "delete":
        return StreamEventDelete(status: rawEvent.payload)
      case "notification":
        let notification = try decoder.decode(Notification.self, from: payloadData)
        return StreamEventNotification(notification: notification)
      case "conversation":
        let conversation = try decoder.decode(Conversation.self, from: payloadData)
        return StreamEventConversation(conversation: conversation)
      default:
        return nil
      }
    } catch {
      print("Error decoding streaming event to final event: \(error.localizedDescription)")
      print("Raw data: \(rawEvent.payload)")
      return nil
    }
  }
}
