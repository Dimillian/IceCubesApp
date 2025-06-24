import Models
import SwiftUI

nonisolated func NotificationRowAppendTextView(notification: ConsolidatedNotification) -> Text {
  if notification.accounts.count > 1 {
    let othersCount: Int
    // For favorites and reblogs, use the actual count from the status
    if notification.type == .favourite, let favCount = notification.status?.favouritesCount,
      favCount > 1
    {
      othersCount = favCount - 1
    } else if notification.type == .reblog, let reblogCount = notification.status?.reblogsCount,
      reblogCount > 1
    {
      othersCount = reblogCount - 1
    } else {
      // For other types (like follow), use the accounts count
      othersCount = notification.accounts.count - 1
    }
    return Text("notifications-others-count \(othersCount)")
      .font(.subheadline)
      .fontWeight(.regular)
      + Text(" ⸱ ")
      .font(.footnote)
      .fontWeight(.regular)
      .foregroundStyle(.secondary)
      + Text(notification.createdAt.relativeFormatted)
      .font(.footnote)
      .fontWeight(.regular)
      .foregroundStyle(.secondary)
  } else {
    return Text(" ")
      + Text(notification.type.label(count: 1))
      .font(.subheadline)
      .fontWeight(.regular)
      + Text(" ⸱ ")
      .font(.footnote)
      .fontWeight(.regular)
      .foregroundStyle(.secondary)
      + Text(notification.createdAt.relativeFormatted)
      .font(.footnote)
      .fontWeight(.regular)
      .foregroundStyle(.secondary)
  }
}
