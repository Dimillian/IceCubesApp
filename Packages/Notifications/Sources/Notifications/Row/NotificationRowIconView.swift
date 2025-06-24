import Models
import SwiftUI

struct NotificationRowIconView: View {
  let type: Models.Notification.NotificationType
  let status: Status?
  let showBorder: Bool

  var body: some View {
    ZStack(alignment: .center) {
      Circle()
        .strokeBorder(showBorder ? Color.white : Color.clear, lineWidth: 1)
        .background(
          Circle().foregroundColor(
            showBorder ? type.tintColor(isPrivate: status?.visibility == .direct) : .clear)
        )
        .frame(width: showBorder ? 28 : 20, height: showBorder ? 28 : 20)

      type.icon(isPrivate: status?.visibility == .direct)
        .resizable()
        .scaledToFit()
        .frame(width: 16, height: 16)
        .foregroundColor(.white)
    }
  }
}
