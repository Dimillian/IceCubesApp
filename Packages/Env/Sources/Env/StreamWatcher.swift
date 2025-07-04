import Combine
import Foundation
import Models
import NetworkClient
import OSLog
import Observation

@MainActor
@Observable public class StreamWatcher {
  private var client: MastodonClient?
  private var task: URLSessionWebSocketTask?
  private var watchedStreams: [Stream] = []
  private var instanceStreamingURL: URL?

  private let decoder = JSONDecoder()
  private let encoder = JSONEncoder()

  private var retryDelay: Int = 10

  public enum Stream: String {
    case federated = "public"
    case local
    case user
    case direct
  }

  public var events: [any StreamEvent] = []
  public var unreadNotificationsCount: Int = 0
  public var latestEvent: (any StreamEvent)?

  private let logger = Logger(subsystem: "com.icecubesapp", category: "stream")

  public static let shared = StreamWatcher()

  private init() {
    decoder.keyDecodingStrategy = .convertFromSnakeCase
  }

  public func setClient(client: MastodonClient, instanceStreamingURL: URL?) {
    if self.client != nil {
      stopWatching()
    }
    self.client = client
    self.instanceStreamingURL = instanceStreamingURL
    connect()
  }

  private func connect() {
    guard
      let task = try? client?.makeWebSocketTask(
        endpoint: Streaming.streaming,
        instanceStreamingURL: instanceStreamingURL
      )
    else {
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
    for stream in streams {
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
              logger.error("Error decoding streaming event string")
              return
            }
            let rawEvent = try decoder.decode(RawStreamEvent.self, from: data)
            logger.info("Stream update: \(rawEvent.event)")
            Task { @MainActor in
              if let event = self.rawEventToEvent(rawEvent: rawEvent) {
                self.events.append(event)
                self.latestEvent = event
                if let event = event as? StreamEventNotification,
                  event.notification.status?.visibility != .direct
                {
                  self.unreadNotificationsCount += 1
                }
              }
            }
          } catch {
            logger.error("Error decoding streaming event: \(error.localizedDescription)")
          }

        default:
          break
        }

        Task { @MainActor in
          self.receiveMessage()
        }

      case .failure:
        Task { @MainActor in
          try? await Task.sleep(for: .seconds(self.retryDelay))
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
      logger.error("Error decoding streaming event to final event: \(error.localizedDescription)")
      logger.error("Raw data: \(rawEvent.payload)")
      return nil
    }
  }

  public func emmitDeleteEvent(for status: String) {
    let event = StreamEventDelete(status: status)
    events.append(event)
    latestEvent = event
  }

  public func emmitEditEvent(for status: Status) {
    let event = StreamEventStatusUpdate(status: status)
    events.append(event)
    latestEvent = event
  }

  public func emmitPostEvent(for status: Status) {
    let event = StreamEventUpdate(status: status)
    events.append(event)
    latestEvent = event
  }
}
