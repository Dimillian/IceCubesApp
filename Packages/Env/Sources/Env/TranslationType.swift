import SwiftUI

public enum TranslationType: String, CaseIterable {
  case useServerIfPossible
  case useDeepl
  case useApple

  public var description: LocalizedStringKey {
    switch self {
    case .useServerIfPossible:
      "Instance"
    case .useDeepl:
      "DeepL"
    case .useApple:
      "Apple Translate"
    }
  }
}
