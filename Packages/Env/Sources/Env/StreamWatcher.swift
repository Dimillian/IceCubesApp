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

  private let encoder = JSONEncoder()

  private var retryDelay: Int = 10

  public enum Stream: String {
    case federated = "public"
    case local
    case user
    case direct
  }

  public var events: [any StreamEvent] = []
  public var latestEvent: (any StreamEvent)?

  private let logger = Logger(subsystem: "com.icecubesapp", category: "stream")

  public static let shared = StreamWatcher()

  private init() {
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
          guard let data = string.data(using: .utf8) else {
            logger.error("Error decoding streaming event string")
            return
          }
          let logger = self.logger
          Task { [weak self] in
            guard let self else { return }
            do {
              let rawEvent = try await Self.decodeRawEvent(from: data)
              logger.info("Stream update: \(rawEvent.event)")
              do {
                let event = try await Self.decodeEvent(from: rawEvent)
                await MainActor.run {
                  if let event {
                    self.events.append(event)
                    self.latestEvent = event
                  }
                }
              } catch {
                logger.error("Error decoding streaming event to final event: \(error.localizedDescription)")
                logger.error("Raw data: \(rawEvent.payload)")
              }
            } catch {
              logger.error("Error decoding streaming event: \(error.localizedDescription)")
            }
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

  @concurrent
  nonisolated private static func decodeRawEvent(from data: Data) async throws -> RawStreamEvent {
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    return try decoder.decode(RawStreamEvent.self, from: data)
  }

  @concurrent
  nonisolated private static func decodeEvent(from rawEvent: RawStreamEvent) async throws
    -> (any StreamEvent)?
  {
    guard let payloadData = rawEvent.payload.data(using: .utf8) else {
      return nil
    }
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
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
