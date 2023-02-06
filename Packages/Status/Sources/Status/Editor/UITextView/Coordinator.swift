import SwiftUI

extension TextView.Representable {
  final class Coordinator: NSObject, UITextViewDelegate {
    
    internal let textView: UIKitTextView
    
    private var originalText: NSMutableAttributedString = .init()
    private var text: Binding<NSMutableAttributedString>
    private var calculatedHeight: Binding<CGFloat>
    
    var didBecomeFirstResponder = false
    
    var getTextView: ((UITextView) -> Void)?
    
    init(text: Binding<NSMutableAttributedString>,
         calculatedHeight: Binding<CGFloat>,
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
      self.getTextView = getTextView
      
      super.init()
      textView.delegate = self
      
      self.getTextView?(textView)
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
      originalText = text.wrappedValue
      DispatchQueue.main.async {
        self.recalculateHeight()
      }
    }
    
    func textViewDidChange(_ textView: UITextView) {
      DispatchQueue.main.async {
        self.text.wrappedValue = NSMutableAttributedString(attributedString: textView.attributedText)
        self.recalculateHeight()
      }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
      return true
    }
  }
  
}

extension TextView.Representable.Coordinator {
  
  func update(representable: TextView.Representable) {
    textView.attributedText = representable.text
    textView.font = representable.font
    textView.adjustsFontForContentSizeCategory = true
    textView.autocapitalizationType = representable.autocapitalization
    textView.autocorrectionType = representable.autocorrection
    textView.isEditable = representable.isEditable
    textView.isSelectable = representable.isSelectable
    textView.dataDetectorTypes = representable.autoDetectionTypes
    textView.allowsEditingTextAttributes = representable.allowsRichText
    textView.keyboardType = representable.keyboard
    
    switch representable.multilineTextAlignment {
    case .leading:
      textView.textAlignment = textView.traitCollection.layoutDirection ~= .leftToRight ? .left : .right
    case .trailing:
      textView.textAlignment = textView.traitCollection.layoutDirection ~= .leftToRight ? .right : .left
    case .center:
      textView.textAlignment = .center
    }
    
    if let value = representable.enablesReturnKeyAutomatically {
      textView.enablesReturnKeyAutomatically = value
    } else {
      textView.enablesReturnKeyAutomatically = false
    }
    
    if let returnKeyType = representable.returnKeyType {
      textView.returnKeyType = returnKeyType
    } else {
      textView.returnKeyType = .default
    }
    
    recalculateHeight()
    textView.setNeedsDisplay()
  }
  
  private func recalculateHeight() {
    let newSize = textView.sizeThatFits(CGSize(width: textView.frame.width, height: .greatestFiniteMagnitude))
    guard calculatedHeight.wrappedValue != newSize.height else { return }
    
    DispatchQueue.main.async { // call in next render cycle.
      self.calculatedHeight.wrappedValue = newSize.height
    }
  }
  
}
