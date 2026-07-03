import SwiftUI

extension TextView {
  struct Representable: UIViewControllerRepresentable {
    @Binding var text: NSMutableAttributedString
    @Binding var calculatedHeight: CGFloat
    @Environment(\.sizeCategory) var sizeCategory

    let keyboard: UIKeyboardType
    var getTextView: ((UITextView) -> Void)?

    func makeUIViewController(context: Context) -> TextViewController {
      TextViewController(textView: context.coordinator.textView)
    }

    func updateUIViewController(_: TextViewController, context: Context) {
      context.coordinator.update(representable: self)
      // Deliberately no automatic becomeFirstResponder here: on iOS 26/27 a
      // focused UITextView in this sheet deadlocks SwiftUI's AttributeGraph
      // when the device rotates ("cycle detected" spam until the system kills
      // the app). Tap the field to start typing; TextViewController drops focus
      // in viewWillTransition, *before* the rotation begins.
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
