import Models
import SwiftUI

/// A utility that creates a suitable combined accessibility label for a `StatusRowView` that is not focused.
@MainActor
struct StatusRowAccessibilityLabel {
  let viewModel: StatusRowViewModel

  var hasSpoiler: Bool {
    viewModel.displaySpoiler && viewModel.finalStatus.spoilerText.asRawText.isEmpty == false
  }

  var isReply: Bool {
    if let accountId = viewModel.status.inReplyToAccountId,
      viewModel.status.mentions.contains(where: { $0.id == accountId })
    {
      return true
    }
    return false
  }

  var isBoost: Bool {
    viewModel.status.reblog != nil
  }

  var filter: Filter? {
    guard viewModel.isFiltered else {
      return nil
    }
    return viewModel.filter?.filter
  }

  func finalLabel() -> Text {
    if let filter {
      switch filter.filterAction {
      case .warn:
        Text("status.filter.filtered-by-\(filter.title)")
      case .hide:
        Text("")
      }
    } else {
      userNamePreamble()
        + Text(
          hasSpoiler
            ? viewModel.finalStatus.spoilerText.asRawText
            : viewModel.finalStatus.content.asRawText
        )
        + Text(
          hasSpoiler
            ? "status.editor.spoiler"
            : ""
        ) + Text(", ") + pollText() + imageAltText()
        + Text(viewModel.finalStatus.createdAt.relativeFormatted) + Text(", ")
        + Text("status.summary.n-replies \(viewModel.finalStatus.repliesCount)") + Text(", ")
        + Text("status.summary.n-boosts \(viewModel.finalStatus.reblogsCount)") + Text(", ")
        + Text("status.summary.n-favorites \(viewModel.finalStatus.favouritesCount)")
    }
  }

  func userNamePreamble() -> Text {
    switch (isReply, isBoost) {
    case (true, false):
      Text("accessibility.status.a-replied-to-\(finalUserDisplayName())") + Text(" ")
    case (_, true):
      Text("accessibility.status.a-boosted-b-\(userDisplayName())-\(finalUserDisplayName())")
        + Text(", ")
    default:
      Text(userDisplayName()) + Text(", ")
    }
  }

  func userDisplayName() -> String {
    viewModel.status.account.displayNameWithoutEmojis.count < 4
      ? viewModel.status.account.safeDisplayName
      : viewModel.status.account.displayNameWithoutEmojis
  }

  func finalUserDisplayName() -> String {
    viewModel.finalStatus.account.displayNameWithoutEmojis.count < 4
      ? viewModel.finalStatus.account.safeDisplayName
      : viewModel.finalStatus.account.displayNameWithoutEmojis
  }

  func imageAltText() -> Text {
    let descriptions = viewModel.finalStatus.mediaAttachments
      .compactMap(\.description)

    if descriptions.count == 1 {
      return Text("accessibility.image.alt-text-\(descriptions[0])") + Text(", ")
    } else if descriptions.count > 1 {
      return Text("accessibility.image.alt-text-\(descriptions[0])") + Text(", ")
        + Text("accessibility.image.alt-text-more.label") + Text(", ")
    } else if viewModel.finalStatus.mediaAttachments.isEmpty == false {
      let differentTypes = Set(
        viewModel.finalStatus.mediaAttachments.compactMap(\.localizedTypeDescription)
      ).sorted()
      return Text(
        "accessibility.status.contains-media.label-\(ListFormatter.localizedString(byJoining: differentTypes))"
      ) + Text(", ")
    } else {
      return Text("")
    }
  }

  func pollText() -> Text {
    if let poll = viewModel.finalStatus.poll {
      let showPercentage = poll.expired || poll.voted ?? false
      let title: LocalizedStringKey =
        poll.expired
        ? "accessibility.status.poll.finished.label"
        : "accessibility.status.poll.active.label"

      return poll.options.enumerated().reduce(into: Text(title)) { text, pair in
        let (index, option) = pair
        let selected = poll.ownVotes?.contains(index) ?? false
        let percentage =
          poll.safeVotersCount > 0 && option.votesCount != nil
          ? Int(round(Double(option.votesCount!) / Double(poll.safeVotersCount) * 100))
          : 0

        text =
          text + Text(selected ? "accessibility.status.poll.selected.label" : "") + Text(", ")
          + Text("accessibility.status.poll.option-prefix-\(index + 1)-of-\(poll.options.count)")
          + Text(", ") + Text(option.title) + Text(showPercentage ? ", \(percentage)%. " : ". ")
      }
    }
    return Text("")
  }
}
