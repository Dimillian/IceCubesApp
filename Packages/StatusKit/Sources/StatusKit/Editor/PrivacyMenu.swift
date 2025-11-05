import Models
import SwiftUI

extension StatusEditor {
  struct PrivacyMenu: View {
    @Binding var visibility: Models.Visibility
    let tint: Color

    var body: some View {
      Menu {
        ForEach(Models.Visibility.allCases, id: \.self) { vis in
          Button {
            visibility = vis
          } label: {
            Label(vis.title, systemImage: vis.iconName)
            Text(vis.subtitle)
          }
        }
      } label: {
        if #available(iOS 26.0, *) {
          makeMenuLabel(visibility: visibility)
            .padding(8)
            .glassEffect()
        } else {
          makeMenuLabel(visibility: visibility)
            .padding(4)
            .overlay(
              RoundedRectangle(cornerRadius: 8)
                .stroke(tint, lineWidth: 1)
            )
        }
      }
    }

    private func makeMenuLabel(visibility: Models.Visibility) -> some View {
      HStack {
        Label(visibility.title, systemImage: visibility.iconName)
          .accessibilityLabel("accessibility.editor.privacy.label")
          .accessibilityValue(visibility.title)
          .accessibilityHint("accessibility.editor.privacy.hint")
        Image(systemName: "chevron.down")
      }
      .font(.scaledFootnote)
    }
  }
}
