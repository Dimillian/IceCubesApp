import SwiftUI

struct ShareToolbarItem: ToolbarContent, @unchecked Sendable {
  let url: URL
  let type: DisplayType

  var body: some ToolbarContent {
    ToolbarItem(placement: .topBarTrailing) {
      MediaUIShareLink(url: url, type: type)
    }
  }
}
