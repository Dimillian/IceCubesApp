import DesignSystem
import EmojiText
import Env
import Models
import SwiftUI

struct AccountFieldsView: View {
  @Environment(Theme.self) private var theme
  @Environment(RouterPath.self) private var routerPath
  
  let fields: [Account.Field]
  let account: Account
  
  var body: some View {
    if !fields.isEmpty {
      if #available(iOS 26.0, *) {
        fieldsContainer
        .padding(8)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("accessibility.tabs.profile.fields.container.label")
        #if os(visionOS)
          .background(Material.thick)
          .cornerRadius(4)
          .overlay(
            RoundedRectangle(cornerRadius: 4)
              .stroke(.gray.opacity(0.35), lineWidth: 1)
          )
        #else
          .glassEffect(.regular.interactive(),
                       in: RoundedRectangle(cornerRadius: 4))
        #endif
      } else {
        fieldsContainer
        .padding(8)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("accessibility.tabs.profile.fields.container.label")
        #if os(visionOS)
          .background(Material.thick)
        #else
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
  
  private var fieldsContainer: some View {
    VStack(alignment: .leading) {
      ForEach(fields) { field in
        HStack {
          VStack(alignment: .leading, spacing: 2) {
            EmojiTextApp(.init(stringValue: field.name), emojis: account.emojis)
              .emojiText.size(Font.scaledHeadlineFont.emojiSize)
              .emojiText.baselineOffset(Font.scaledHeadlineFont.emojiBaselineOffset)
              .font(.scaledHeadline)
            HStack {
              if field.verifiedAt != nil {
                Image(systemName: "checkmark.seal")
                  .foregroundColor(Color.green.opacity(0.80))
                  .accessibilityHidden(true)
              }
              EmojiTextApp(field.value, emojis: account.emojis)
                .emojiText.size(Font.scaledBodyFont.emojiSize)
                .emojiText.baselineOffset(Font.scaledBodyFont.emojiBaselineOffset)
                .foregroundColor(theme.tintColor)
                .environment(
                  \.openURL,
                  OpenURLAction { url in
                    routerPath.handle(url: url)
                  }
                )
                .accessibilityValue(
                  field.verifiedAt != nil
                    ? "accessibility.tabs.profile.fields.verified.label" : "")
            }
            .font(.scaledBody)
            if fields.last != field {
              Divider()
                .padding(.vertical, 4)
            }
          }
          Spacer()
        }
        .accessibilityElement(children: .combine)
        .modifier(
          ConditionalUserDefinedFieldAccessibilityActionModifier(
            field: field, routerPath: routerPath))
      }
    }
  }
}

/// A ``ViewModifier`` that creates a attaches an accessibility action if the field value is a valid link
private struct ConditionalUserDefinedFieldAccessibilityActionModifier: ViewModifier {
  let field: Account.Field
  let routerPath: RouterPath

  func body(content: Content) -> some View {
    if let url = URL(string: field.value.asRawText), UIApplication.shared.canOpenURL(url) {
      content
        .accessibilityAction {
          let _ = routerPath.handle(url: url)
        }
        // SwiftUI will automatically decorate this element with the link trait, so we remove the button trait manually.
        // March 18th, 2023: The button trait is still re-applied…
        .accessibilityRemoveTraits(.isButton)
        .accessibilityInputLabels([field.name])
    } else {
      content
        // This element is not interactive; setting this property removes its button trait
        .accessibilityRespondsToUserInteraction(false)
    }
  }
}
