import Foundation
import SwiftUI

// Functions to cope with extending SF symbols
// images named in lower case are Apple's symbols
// images inamed in CamelCase are custom

extension Label where Title == Text, Icon == Image {
  public init(_ title: LocalizedStringKey, imageNamed: String) {
    if imageNamed.lowercased() == imageNamed {
      self.init(title, systemImage: imageNamed)
    } else {
      self.init(title, image: imageNamed)
    }
  }
}
