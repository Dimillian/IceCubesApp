import DesignSystem
import Models
import Network
import SwiftUI
import Timeline
import WidgetKit

struct AccountWidgetView: View {
  var entry: AccountWidgetProvider.Entry

  @Environment(\.widgetFamily) var family
  @Environment(\.redactionReasons) var redacted


  var body: some View {
    VStack(alignment: .center, spacing: 4) {
      if let avatar = entry.avatar {
        Image(uiImage: avatar)
          .resizable()
          .frame(width: 64, height: 64)
          .clipShape(Circle())
        Text("\(entry.account.followersCount ?? 0)")
          .font(.title)
          .fontDesign(.rounded)
          .fontWeight(.bold)
          .monospacedDigit()
        Text("Followers")
          .font(.headline)
          .foregroundStyle(.secondary)
      }
    }
    .frame(maxWidth: .infinity)
  }
}
