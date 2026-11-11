import SwiftUI

extension TextView {
  struct Representable: UIViewControllerRepresentable {
    @Binding var text: NSMutableAttributedString
    @Binding var calculatedHeight: CGFloat
    @Environment(\.dynamicTypeSize) var dynamicTypeSize

    let keyboard: UIKeyboardType
    var getTextView: ((UITextView) -> Void)?

    func makeUIViewController(context: Context) -> TextViewController {
      TextViewController(textView: context.coordinator.textView)
    }

    func updateUIViewController(_: TextViewController, context: Context) {
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
        dynamicTypeSize: dynamicTypeSize,
        getTextView: getTextView
      )
    }
  }
}
