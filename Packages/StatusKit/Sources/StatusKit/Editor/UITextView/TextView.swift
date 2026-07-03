import DesignSystem
import SwiftUI

/// A SwiftUI TextView implementation that supports both scrolling and auto-sizing layouts
public struct TextView: View {
  @Environment(\.layoutDirection) private var layoutDirection

  @Binding private var text: NSMutableAttributedString
  @Binding private var isEmpty: Bool

  @State private var calculatedHeight: CGFloat = 44

  private var getTextView: ((UITextView) -> Void)?

  var placeholderView: AnyView?
  var placeholderText: String?
  var keyboard: UIKeyboardType = .default

  /// Makes a new TextView that supports `NSAttributedString`
  /// - Parameters:
  ///   - text: A binding to the attributed text
  public init(
    _ text: Binding<NSMutableAttributedString>,
    getTextView: ((UITextView) -> Void)? = nil
  ) {
    _text = text
    _isEmpty = Binding(
      get: { text.wrappedValue.string.isEmpty },
      set: { _ in }
    )

    self.getTextView = getTextView
  }

  public var body: some View {
    Representable(
      text: $text,
      calculatedHeight: $calculatedHeight,
      keyboard: keyboard,
      getTextView: getTextView
    )
    .frame(
      minHeight: calculatedHeight,
      maxHeight: calculatedHeight
    )
    .accessibilityValue(
      $text.wrappedValue.string.isEmpty ? (placeholderText ?? "") : $text.wrappedValue.string
    )
    .background(
      placeholderView?
        .foregroundColor(Color(.placeholderText))
        .multilineTextAlignment(.leading)
        .font(.scaledBody)
        .padding(.horizontal, 0)
        .padding(.vertical, 0)
        .opacity(isEmpty ? 1 : 0)
        .accessibilityHidden(true),
      alignment: .topLeading
    )
  }
}

/// Hosts the editor's `UIKitTextView` so the editor gets a `viewWillTransition`
/// hook on the owning view controller.
///
/// iOS 26/27: a focused `UITextView` inside the compose sheet deadlocks
/// SwiftUI's AttributeGraph when the interface rotates ("cycle detected" spam
/// until the watchdog kills the app). `viewWillTransition(to:with:)` fires
/// *before* the rotation animation begins, so resigning first responder here
/// dismisses the keyboard in time to prevent the cycle from ever forming — the
/// device-orientation observer in `UIKitTextView` only lands afterwards and so
/// can't. It stays as a post-rotation backstop.
final class TextViewController: UIViewController {
  private let textView: UIKitTextView

  init(textView: UIKitTextView) {
    self.textView = textView
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func loadView() {
    // The text view *is* the controller's view, so SwiftUI sizes it exactly as
    // it did when the representable vended the UITextView directly.
    view = textView
  }

  override func viewWillTransition(
    to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator
  ) {
    if textView.isFirstResponder {
      textView.resignFirstResponder()
    }
    super.viewWillTransition(to: size, with: coordinator)
  }
}

final class UIKitTextView: UITextView {
  override init(frame: CGRect, textContainer: NSTextContainer?) {
    super.init(frame: frame, textContainer: textContainer)
    // iOS 26/27 backstop: dropping focus before rotation happens in
    // TextViewController.viewWillTransition. This post-rotation observer only
    // helps settle layout if a transition was left half-finished.
    UIDevice.current.beginGeneratingDeviceOrientationNotifications()
    NotificationCenter.default.addObserver(
      self, selector: #selector(deviceOrientationDidChange),
      name: UIDevice.orientationDidChangeNotification, object: nil)
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override var keyCommands: [UIKeyCommand]? {
    (super.keyCommands ?? []) + [
      UIKeyCommand(
        input: UIKeyCommand.inputEscape, modifierFlags: [], action: #selector(escape(_:)))
    ]
  }

  @objc private func escape(_: Any) {
    resignFirstResponder()
  }

  @objc private func deviceOrientationDidChange() {
    // This lands only after the interface has already switched orientation, so
    // it can't prevent the iOS 26 rotation deadlock — but if we were focused
    // through a rotation and the transition was left half-finished, dropping
    // focus here lets UIKit settle the layout and resume touch delivery.
    guard isFirstResponder,
      UIDevice.current.orientation.isValidInterfaceOrientation
    else { return }
    resignFirstResponder()
  }
}
