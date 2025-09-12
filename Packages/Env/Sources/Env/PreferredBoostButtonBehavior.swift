import Foundation
import SwiftUI

public enum PreferredBoostButtonBehavior: Int, CaseIterable, Codable {
  case both
  case boostOnly
  case quoteOnly

  public var title: LocalizedStringKey {
    switch self {
    case .both:
      "Boost & Quote"
    case .boostOnly:
      "Boost Only"
    case .quoteOnly:
      "Quote Only"
    }
  }
}
