import SwiftUI

public extension TextView {
  
  /// Specifies whether or not this view allows rich text
  /// - Parameter enabled: If `true`, rich text editing controls will be enabled for the user
  func allowsRichText(_ enabled: Bool) -> TextView {
    var view = self
    view.allowRichText = enabled
    return view
  }
  
  /// Specify a placeholder text
  /// - Parameter placeholder: The placeholder text
  func placeholder(_ placeholder: String) -> TextView {
    self.placeholder(placeholder) { $0 }
  }
  
  /// Specify a placeholder with the specified configuration
  ///
  /// Example:
  ///
  ///     TextView($text)
  ///         .placeholder("placeholder") { view in
  ///             view.foregroundColor(.red)
  ///         }
  func placeholder<V: View>(_ placeholder: String, _ configure: (Text) -> V) -> TextView {
    var view = self
    let text = Text(placeholder)
    view.placeholderView = AnyView(configure(text))
    return view
  }
  
  /// Specify a custom placeholder view
  func placeholder<V: View>(_ placeholder: V) -> TextView {
    var view = self
    view.placeholderView = AnyView(placeholder)
    return view
  }
  
  /// Enables auto detection for the specified types
  /// - Parameter types: The types to detect
  func autoDetectDataTypes(_ types: UIDataDetectorTypes) -> TextView {
    var view = self
    view.autoDetectionTypes = types
    return view
  }
  
  /// Specify the foreground color for the text
  /// - Parameter color: The foreground color
  func foregroundColor(_ color: UIColor) -> TextView {
    var view = self
    view.foregroundColor = color
    return view
  }
  
  /// Specifies the capitalization style to apply to the text
  /// - Parameter style: The capitalization style
  func autocapitalization(_ style: UITextAutocapitalizationType) -> TextView {
    var view = self
    view.autocapitalization = style
    return view
  }
  
  /// Specifies the alignment of multi-line text
  /// - Parameter alignment: The text alignment
  func multilineTextAlignment(_ alignment: TextAlignment) -> TextView {
    var view = self
    view.multilineTextAlignment = alignment
    return view
  }
  
  func setKeyboardType(_ keyboardType: UIKeyboardType) -> TextView {
    var view = self
    view.keyboard = keyboardType
    return view
  }
  
  /// Specifies the font to apply to the text
  /// - Parameter font: The font to apply
  func font(_ font: UIFont) -> TextView {
    var view = self
    view.font = font
    return view
  }
  
  /// Specifies if the field should clear its content when editing begins
  /// - Parameter value: If true, the field will be cleared when it receives focus
  func clearOnInsertion(_ value: Bool) -> TextView {
    var view = self
    view.clearsOnInsertion = value
    return view
  }
  
  /// Disables auto-correct
  /// - Parameter disable: If true, autocorrection will be disabled
  func disableAutocorrection(_ disable: Bool?) -> TextView {
    var view = self
    if let disable = disable {
      view.autocorrection = disable ? .no : .yes
    } else {
      view.autocorrection = .default
    }
    return view
  }
  
  /// Specifies whether the text can be edited
  /// - Parameter isEditable: If true, the text can be edited via the user's keyboard
  func isEditable(_ isEditable: Bool) -> TextView {
    var view = self
    view.isEditable = isEditable
    return view
  }
  
  /// Specifies whether the text can be selected
  /// - Parameter isSelectable: If true, the text can be selected
  func isSelectable(_ isSelectable: Bool) -> TextView {
    var view = self
    view.isSelectable = isSelectable
    return view
  }
  
  /// Specifies the type of return key to be shown during editing, for the device keyboard
  /// - Parameter style: The return key style
  func returnKey(_ style: UIReturnKeyType?) -> TextView {
    var view = self
    view.returnKeyType = style
    return view
  }
  
  /// Specifies whether the return key should auto enable/disable based on the current text
  /// - Parameter value: If true, when the text is empty the return key will be disabled
  func automaticallyEnablesReturn(_ value: Bool?) -> TextView {
    var view = self
    view.enablesReturnKeyAutomatically = value
    return view
  }
  
  /// Specifies the truncation mode for this field
  /// - Parameter mode: The truncation mode
  func truncationMode(_ mode: Text.TruncationMode) -> TextView {
    var view = self
    switch mode {
    case .head: view.truncationMode = .byTruncatingHead
    case .tail: view.truncationMode = .byTruncatingTail
    case .middle: view.truncationMode = .byTruncatingMiddle
    @unknown default:
      fatalError("Unknown text truncation mode")
    }
    return view
  }
  
}
