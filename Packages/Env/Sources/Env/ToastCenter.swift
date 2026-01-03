import SwiftUI

@MainActor
@Observable
public final class ToastCenter {
  public struct Toast: Identifiable, Equatable {
    public enum Kind: Equatable {
      case message
      case progress
    }

    public let id: UUID
    public var title: String
    public var message: String?
    public var systemImage: String?
    public var tint: Color
    public var kind: Kind
    public var progress: Double?

    public init(
      id: UUID = UUID(),
      title: String,
      message: String? = nil,
      systemImage: String? = nil,
      tint: Color = .accentColor,
      kind: Kind = .message,
      progress: Double? = nil
    ) {
      self.id = id
      self.title = title
      self.message = message
      self.systemImage = systemImage
      self.tint = tint
      self.kind = kind
      self.progress = progress
    }
  }

  public static let shared = ToastCenter()

  public var toast: Toast?
  private var dismissalTask: Task<Void, Never>?

  @discardableResult
  public func show(_ toast: Toast, autoDismissAfter: Swift.Duration? = nil) -> UUID {
    dismissalTask?.cancel()
    self.toast = toast
    scheduleDismiss(after: autoDismissAfter)
    return toast.id
  }

  @discardableResult
  public func showProgress(
    title: String,
    message: String? = nil,
    systemImage: String? = nil,
    tint: Color = .accentColor,
    progress: Double? = nil
  ) -> UUID {
    let toast = Toast(
      title: title,
      message: message,
      systemImage: systemImage,
      tint: tint,
      kind: .progress,
      progress: progress
    )
    return show(toast)
  }

  public func showTask(
    title: String,
    message: String? = nil,
    systemImage: String? = nil,
    tint: Color = .accentColor,
    task: @escaping @Sendable () async throws -> Void,
    successToast: Toast? = nil,
    failureToast: ((Error) -> Toast)? = nil
  ) {
    let toastID = showProgress(
      title: title,
      message: message,
      systemImage: systemImage,
      tint: tint
    )

    Task {
      do {
        try await task()
        if let successToast {
          update(id: toastID, toast: successToast, autoDismissAfter: Swift.Duration.seconds(3))
        } else {
          dismiss(id: toastID)
        }
      } catch {
        if let failureToast {
          update(id: toastID, toast: failureToast(error), autoDismissAfter: Swift.Duration.seconds(4))
        } else {
          dismiss(id: toastID)
        }
      }
    }
  }

  public func update(id: UUID, toast: Toast, autoDismissAfter: Swift.Duration? = nil) {
    guard self.toast?.id == id else { return }
    dismissalTask?.cancel()
    self.toast = toast
    scheduleDismiss(after: autoDismissAfter)
  }

  public func updateProgress(id: UUID, progress: Double) {
    guard var toast, toast.id == id else { return }
    toast.progress = progress
    self.toast = toast
  }

  public func dismiss(id: UUID? = nil) {
    if let id {
      guard toast?.id == id else { return }
    }
    dismissalTask?.cancel()
    toast = nil
  }

  private func scheduleDismiss(after duration: Swift.Duration?) {
    guard let duration else { return }
    dismissalTask = Task {
      try? await Task.sleep(for: duration)
      guard !Task.isCancelled else { return }
      toast = nil
    }
  }
}
