import SwiftUI

extension StatusEditor {
  enum EditorFocusState: Hashable {
    case main
    case followUp(index: UUID)
  }
}
