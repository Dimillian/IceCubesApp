import DesignSystem
import Env
import Models
import NukeUI
import SwiftUI

extension StatusEditor {
  @MainActor
  struct CustomEmojisView: View {
    @Environment(\.dismiss) private var dismiss

    @Environment(Theme.self) private var theme

    var viewModel: ViewModel

    var body: some View {
      NavigationStack {
        ScrollView {
          ForEach(viewModel.customEmojiContainer) { container in
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 40, maximum: 40))], spacing: 9) {
              Section {
                ForEach(container.emojis) { emoji in
                  LazyImage(url: emoji.url) { state in
                    if let image = state.image {
                      image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 40, height: 40)
                        .accessibilityLabel(emoji.shortcode.replacingOccurrences(of: "_", with: " "))
                        .accessibilityAddTraits(.isButton)
                    } else if state.isLoading {
                      Rectangle()
                        .fill(Color.gray)
                        .frame(width: 40, height: 40)
                        .accessibility(hidden: true)
                    }
                  }
                  .onTapGesture {
                    viewModel.insertStatusText(text: " :\(emoji.shortcode): ")
                  }
                }
              } header: {
                HStack {
                  Text(container.categoryName)
                    .font(.scaledFootnote)
                  Spacer()
                }
              }
            }
            .padding(.horizontal, 8)
          }
        }
        .toolbar {
          CancelToolbarItem()
        }
        .scrollContentBackground(.hidden)
        .navigationTitle("status.editor.emojis.navigation-title")
        .navigationBarTitleDisplayMode(.inline)
      }
      .presentationBackground(.thinMaterial)
      .presentationCornerRadius(16)
      .presentationDetents([.medium])
    }
  }
}
