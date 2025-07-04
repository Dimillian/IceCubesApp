import DesignSystem
import EmojiText
import Env
import Models
import StatusKit
import SwiftUI

struct AccountInfoView: View {
  @Environment(Theme.self) private var theme
  @Environment(RouterPath.self) private var routerPath
  
  let account: Account
  let relationship: Relationship?
  let isCurrentUser: Bool
  @Binding var followButtonViewModel: FollowButtonViewModel?
  @Binding var translation: Translation?
  @Binding var isLoadingTranslation: Bool
  
  var body: some View {
    HStack(alignment: .firstTextBaseline) {
      VStack(alignment: .leading, spacing: 0) {
        nameAndBadgesView
        usernameView
        movedToView
        joinedAtView
      }
      .accessibilityElement(children: .contain)
      .accessibilitySortPriority(1)

      Spacer()
      
      followButtonView
    }
    
    relationshipNoteView
    
    accountBioView
    
    translationView
  }
  
  private var nameAndBadgesView: some View {
    HStack(alignment: .center, spacing: 2) {
      EmojiTextApp(.init(stringValue: account.safeDisplayName), emojis: account.emojis)
        .font(.scaledHeadline)
        .foregroundColor(theme.labelColor)
        .emojiText.size(Font.scaledHeadlineFont.emojiSize)
        .emojiText.baselineOffset(Font.scaledHeadlineFont.emojiBaselineOffset)
        .accessibilityAddTraits(.isHeader)

      // The views here are wrapped in ZStacks as a Text(Image) does not provide an `accessibilityLabel`.
      if account.bot {
        ZStack {
          Text(Image(systemName: "poweroutlet.type.b.fill"))
            .font(.footnote)
        }.accessibilityLabel("accessibility.tabs.profile.user.account-bot.label")
      }
      if account.locked {
        ZStack {
          Text(Image(systemName: "lock.fill"))
            .font(.footnote)
        }.accessibilityLabel("accessibility.tabs.profile.user.account-private.label")
      }
      if relationship?.blocking == true {
        ZStack {
          Text(Image(systemName: "person.crop.circle.badge.xmark.fill"))
            .font(.footnote)
        }.accessibilityLabel("accessibility.tabs.profile.user.account-blocked.label")
      }
      if relationship?.muting == true {
        ZStack {
          Text(Image(systemName: "speaker.slash.fill"))
            .font(.footnote)
        }.accessibilityLabel("accessibility.tabs.profile.user.account-muted.label")
      }
    }
  }
  
  private var usernameView: some View {
    Text("@\(account.acct)")
      .font(.scaledCallout)
      .foregroundStyle(.secondary)
      .textSelection(.enabled)
      .accessibilityRespondsToUserInteraction(false)
  }
  
  @ViewBuilder
  private var movedToView: some View {
    if let movedTo = account.moved {
      Button("account.movedto.redirect-\("@\(movedTo.acct)")") {
        routerPath.navigate(to: .accountDetailWithAccount(account: movedTo))
      }
      .font(.scaledCallout)
      .foregroundColor(.accentColor)
    }
  }
  
  @ViewBuilder
  private var joinedAtView: some View {
    let joinedAt = account.createdAt.asDate
    HStack(spacing: 4) {
      Image(systemName: "calendar")
        .accessibilityHidden(true)
      Text("account.joined")
      Text(joinedAt, style: .date)
    }
    .foregroundStyle(.secondary)
    .font(.footnote)
    .padding(.top, 6)
    .accessibilityElement(children: .combine)
  }
  
  private var followButtonView: some View {
    HStack {
      if let followButtonViewModel = followButtonViewModel, !isCurrentUser {
        FollowButton(viewModel: followButtonViewModel)
      } else if !isCurrentUser {
        ProgressView()
      }
    }
    .padding(.top, 4)
  }
  
  @ViewBuilder
  private var relationshipNoteView: some View {
    if let note = relationship?.note, !note.isEmpty, !isCurrentUser {
      VStack(alignment: .leading, spacing: 4) {
        Text("account.relation.note.label")
          .foregroundStyle(.secondary)
        Text(note)
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(8)
          #if !os(visionOS)
            .background(theme.secondaryBackgroundColor)
          #endif
          .cornerRadius(4)
          .overlay(
            RoundedRectangle(cornerRadius: 4)
              .stroke(.gray.opacity(0.35), lineWidth: 1)
          )
      }
    }
  }
  
  private var accountBioView: some View {
    EmojiTextApp(account.note, emojis: account.emojis)
      .font(.scaledBody)
      .foregroundColor(theme.labelColor)
      .emojiText.size(Font.scaledBodyFont.emojiSize)
      .emojiText.baselineOffset(Font.scaledBodyFont.emojiBaselineOffset)
      .padding(.top, 8)
      .textSelection(.enabled)
      .environment(
        \.openURL,
        OpenURLAction { url in
          routerPath.handle(url: url)
        }
      )
      .accessibilityRespondsToUserInteraction(false)
  }
  
  @ViewBuilder
  private var translationView: some View {
    if let translation = translation, !isLoadingTranslation {
      GroupBox {
        VStack(alignment: .leading, spacing: 4) {
          Text(translation.content.asSafeMarkdownAttributedString)
            .font(.scaledBody)
          Text(
            getLocalizedStringLabel(
              langCode: translation.detectedSourceLanguage, provider: translation.provider)
          )
          .font(.footnote)
          .foregroundStyle(.secondary)
        }
      }
      .fixedSize(horizontal: false, vertical: true)
    }
  }
  
  private func getLocalizedStringLabel(langCode: String, provider: String) -> String {
    if let localizedLanguage = Locale.current.localizedString(forLanguageCode: langCode) {
      let format = NSLocalizedString("status.action.translated-label-from-%@-%@", comment: "")
      return String.localizedStringWithFormat(format, localizedLanguage, provider)
    } else {
      return "status.action.translated-label-\(provider)"
    }
  }
}