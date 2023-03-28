import SwiftUI

extension TextView {
  struct Representable: UIViewRepresentable {
    @Binding var text: NSMutableAttributedString
    @Binding var calculatedHeight: CGFloat
    @Environment(\.sizeCategory) var sizeCategory

    let keyboard: UIKeyboardType
    var getTextView: ((UITextView) -> Void)?

    func makeUIView(context: Context) -> UIKitTextView {
      context.coordinator.textView
    }

    func updateUIView(_: UIKitTextView, context: Context) {
      context.coordinator.update(representable: self)
      if !context.coordinator.didBecomeFirstResponder {
        context.coordinator.textView.becomeFirstResponder()
        context.coordinator.didBecomeFirstResponder = true
      }
    }

    @discardableResult func makeCoordinator() -> Coordinator {
      Coordinator(
        text: $text,
        calculatedHeight: $calculatedHeight,
        sizeCategory: sizeCategory,
        getTextView: getTextView
      )
    }
  }
}
