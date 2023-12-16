import SwiftUI

enum StatusEditorFocusState: Hashable {
  case main, followUp(index: UUID)
}
