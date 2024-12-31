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

final class UIKitTextView: UITextView {
  override var keyCommands: [UIKeyCommand]? {
    (super.keyCommands ?? []) + [
      UIKeyCommand(
        input: UIKeyCommand.inputEscape, modifierFlags: [], action: #selector(escape(_:)))
    ]
  }

  @objc private func escape(_: Any) {
    resignFirstResponder()
  }
}
