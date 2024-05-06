import WidgetKit
import SwiftUI

@main
struct IceCubesAppWidgetsExtensionBundle: WidgetBundle {
  var body: some Widget {
    LatestPostsWidget()
    HashtagPostsWidget()
    MentionsWidget()
  }
}
