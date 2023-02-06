import SwiftUI

/// A SwiftUI TextView implementation that supports both scrolling and auto-sizing layouts
public struct TextView: View {
  
  @Environment(\.layoutDirection) private var layoutDirection
  
  @Binding private var text: NSMutableAttributedString
  @Binding private var isEmpty: Bool
  
  @State private var calculatedHeight: CGFloat = 44
  
  private var getTextView: ((UITextView) -> Void)?
  
  var placeholderView: AnyView?
  var foregroundColor: UIColor = .label
  var autocapitalization: UITextAutocapitalizationType = .sentences
  var multilineTextAlignment: TextAlignment = .leading
  var font: UIFont = .preferredFont(forTextStyle: .body)
  var returnKeyType: UIReturnKeyType?
  var clearsOnInsertion: Bool = false
  var autocorrection: UITextAutocorrectionType = .default
  var truncationMode: NSLineBreakMode = .byTruncatingTail
  var keyboard: UIKeyboardType = .default
  var isEditable: Bool = true
  var isSelectable: Bool = true
  var enablesReturnKeyAutomatically: Bool?
  var autoDetectionTypes: UIDataDetectorTypes = []
  var allowRichText: Bool
  
  /// Makes a new TextView that supports `NSAttributedString`
  /// - Parameters:
  ///   - text: A binding to the attributed text
  public init(_ text: Binding<NSMutableAttributedString>,
              getTextView: ((UITextView) -> Void)? = nil
  ) {
    _text = text
    _isEmpty = Binding(
      get: { text.wrappedValue.string.isEmpty },
      set: { _ in }
    )
    
    self.getTextView = getTextView
    
    allowRichText = true
  }
  
  public var body: some View {
    Representable(
      text: $text,
      calculatedHeight: $calculatedHeight,
      foregroundColor: foregroundColor,
      autocapitalization: autocapitalization,
      multilineTextAlignment: multilineTextAlignment,
      font: font,
      returnKeyType: returnKeyType,
      clearsOnInsertion: clearsOnInsertion,
      autocorrection: autocorrection,
      truncationMode: truncationMode,
      isEditable: isEditable,
      keyboard: keyboard,
      isSelectable: isSelectable,
      enablesReturnKeyAutomatically: enablesReturnKeyAutomatically,
      autoDetectionTypes: autoDetectionTypes,
      allowsRichText: allowRichText,
      getTextView: getTextView
    )
    .frame(
      minHeight: calculatedHeight,
      maxHeight: calculatedHeight
    )
    .background(
      placeholderView?
        .foregroundColor(Color(.placeholderText))
        .multilineTextAlignment(multilineTextAlignment)
        .font(Font(font))
        .padding(.horizontal, 0)
        .padding(.vertical, 0)
        .opacity(isEmpty ? 1 : 0),
      alignment: .topLeading
    )
  }
  
}

final class UIKitTextView: UITextView {
  
  override var keyCommands: [UIKeyCommand]? {
    return (super.keyCommands ?? []) + [
      UIKeyCommand(input: UIKeyCommand.inputEscape, modifierFlags: [], action: #selector(escape(_:)))
    ]
  }
  
  @objc private func escape(_ sender: Any) {
    resignFirstResponder()
  }
  
}
