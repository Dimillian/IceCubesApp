import Models
import SwiftUI

extension StatusEditor {
  struct PrivacyMenu: View {
    @Binding var visibility: Models.Visibility
    let tint: Color

    var body: some View {
      Menu {
        ForEach(Models.Visibility.allCases, id: \.self) { vis in
          Button { visibility = vis } label: {
            Label(vis.title, systemImage: vis.iconName)
          }
        }
      } label: {
        HStack {
          Label(visibility.title, systemImage: visibility.iconName)
            .accessibilityLabel("accessibility.editor.privacy.label")
            .accessibilityValue(visibility.title)
            .accessibilityHint("accessibility.editor.privacy.hint")
          Image(systemName: "chevron.down")
        }
        .font(.scaledFootnote)
        .padding(4)
        .overlay(
          RoundedRectangle(cornerRadius: 8)
            .stroke(tint, lineWidth: 1)
        )
      }
    }
  }
}
