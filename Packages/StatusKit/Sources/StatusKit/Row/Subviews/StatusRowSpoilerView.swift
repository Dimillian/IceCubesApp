import DesignSystem
import Models
import SwiftUI

struct StatusRowSpoilerView: View {
  let status: AnyStatus
  @Binding var displaySpoiler: Bool

  var body: some View {
    HStack(alignment: .top) {
      Text("⚠︎")
        .font(.system(.subheadline, weight: .bold))
        .foregroundStyle(.secondary)
      EmojiTextApp(status.spoilerText, emojis: status.emojis, language: status.language)
        .font(.system(.subheadline, weight: .bold))
        .emojiText.size(Font.scaledSubheadlineFont.emojiSize)
        .emojiText.baselineOffset(Font.scaledSubheadlineFont.emojiBaselineOffset)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.leading)
      Spacer()
      Button {
        withAnimation {
          displaySpoiler.toggle()
        }
      } label: {
        Image(systemName: "chevron.down")
          .rotationEffect(Angle(degrees: displaySpoiler ? 0 : 180))
      }
      .buttonStyle(.bordered)
      .accessibilityLabel(displaySpoiler ? Text("status.show-more") : Text("status.show-less"))
      .accessibilityHidden(true)
    }
    .contentShape(Rectangle())
    .onTapGesture {  // make whole row tapable to make up for smaller button size
      withAnimation {
        displaySpoiler.toggle()
      }
    }
  }
}
