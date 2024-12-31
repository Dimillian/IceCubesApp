import DesignSystem
import SwiftUI

extension TextView.Representable {
  final class Coordinator: NSObject, UITextViewDelegate {
    let textView: UIKitTextView

    private var originalText: NSMutableAttributedString = .init()
    private var text: Binding<NSMutableAttributedString>
    private var sizeCategory: ContentSizeCategory
    private var calculatedHeight: Binding<CGFloat>

    var didBecomeFirstResponder = false

    var getTextView: ((UITextView) -> Void)?

    init(
      text: Binding<NSMutableAttributedString>,
      calculatedHeight: Binding<CGFloat>,
      sizeCategory: ContentSizeCategory,
      getTextView: ((UITextView) -> Void)?
    ) {
      textView = UIKitTextView()
      textView.backgroundColor = .clear
      textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
      textView.isScrollEnabled = false
      textView.textContainer.lineFragmentPadding = 0
      textView.textContainerInset = .zero

      self.text = text
      self.calculatedHeight = calculatedHeight
      self.sizeCategory = sizeCategory
      self.getTextView = getTextView

      super.init()

      textView.delegate = self

      textView.font = Font.scaledBodyUIFont
      textView.adjustsFontForContentSizeCategory = true
      textView.autocapitalizationType = .sentences
      textView.autocorrectionType = .yes
      textView.isEditable = true
      textView.isSelectable = true
      textView.dataDetectorTypes = []
      textView.allowsEditingTextAttributes = false
      textView.returnKeyType = .default
      textView.allowsEditingTextAttributes = true
      textView.inlinePredictionType = .no

      self.getTextView?(textView)
    }

    func textViewDidBeginEditing(_: UITextView) {
      originalText = text.wrappedValue
      DispatchQueue.main.async {
        self.recalculateHeight()
      }
    }

    func textViewDidChange(_ textView: UITextView) {
      DispatchQueue.main.async {
        self.text.wrappedValue = NSMutableAttributedString(
          attributedString: textView.attributedText)
        self.recalculateHeight()
      }
    }

    func textView(_: UITextView, shouldChangeTextIn _: NSRange, replacementText _: String) -> Bool {
      true
    }
  }
}

extension TextView.Representable.Coordinator {
  func update(representable: TextView.Representable) {
    textView.keyboardType = representable.keyboard
    recalculateHeight()
    textView.setNeedsDisplay()
  }

  private func recalculateHeight() {
    let newSize = textView.sizeThatFits(
      CGSize(width: textView.frame.width, height: .greatestFiniteMagnitude))
    guard calculatedHeight.wrappedValue != newSize.height else { return }

    DispatchQueue.main.async {  // call in next render cycle.
      self.calculatedHeight.wrappedValue = newSize.height
    }
  }
}
