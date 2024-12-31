import SwiftUI
import WidgetKit

@main
struct IceCubesAppWidgetsExtensionBundle: WidgetBundle {
  var body: some Widget {
    LatestPostsWidget()
    HashtagPostsWidget()
    ListsPostWidget()
    MentionsWidget()
    AccountWidget()
  }
}
