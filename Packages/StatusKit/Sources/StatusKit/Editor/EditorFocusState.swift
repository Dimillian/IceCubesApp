import SwiftUI

extension StatusEditor {
  enum EditorFocusState: Hashable {
    case main, followUp(index: UUID)
  }
}
