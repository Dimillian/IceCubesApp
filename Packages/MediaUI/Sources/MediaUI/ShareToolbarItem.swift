import SwiftUI

struct ShareToolbarItem: ToolbarContent, @unchecked Sendable {
  let url: URL
  let type: DisplayType

  var body: some ToolbarContent {
    ToolbarItem(placement: .topBarTrailing) {
      if type == .image {
        let transferable = MediaUIImageTransferable(url: url)
        ShareLink(item: transferable, preview: .init("status.media.contextmenu.share",
                                                     image: transferable))
      } else {
        ShareLink(item: url)
      }
    }
  }
}
