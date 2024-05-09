import DesignSystem
import Env
import Models
import SwiftUI

@MainActor
struct StatusRowTranslateView: View {
  @Environment(\.isInCaptureMode) private var isInCaptureMode: Bool
  @Environment(\.isCompact) private var isCompact: Bool

  @Environment(UserPreferences.self) private var preferences

  var viewModel: StatusRowViewModel

  private var shouldShowTranslateButton: Bool {
    let statusLang = viewModel.getStatusLang()

    if let userLang = preferences.serverPreferences?.postLanguage,
       preferences.showTranslateButton,
       !viewModel.finalStatus.content.asRawText.isEmpty,
       viewModel.translation == nil
    {
      return userLang != statusLang
    } else {
      return false
    }
  }

  private func getLocalizedString(langCode: String, provider: String) -> String {
    if let localizedLanguage = Locale.current.localizedString(forLanguageCode: langCode) {
      let format = NSLocalizedString("status.action.translated-label-from-%@-%@", comment: "")
      return String.localizedStringWithFormat(format, localizedLanguage, provider)
    } else {
      return "status.action.translated-label-\(provider)"
    }
  }

  @ViewBuilder
  var translateButton: some View {
    if !isInCaptureMode,
       !isCompact,
       let userLang = preferences.serverPreferences?.postLanguage,
       shouldShowTranslateButton
    {
      Button {
        Task {
          await viewModel.translate(userLang: userLang)
        }
      } label: {
        if viewModel.isLoadingTranslation {
          ProgressView()
        } else {
          Text("status.action.translate")
        }
      }
      .buttonStyle(.borderless)
    }
  }

  @ViewBuilder
  var generalTranslateButton: some View {
    translateButton
  }

  var body: some View {
    generalTranslateButton
      .onChange(of: preferences.preferredTranslationType) { _, _ in
        withAnimation {
          _ = viewModel.updatePreferredTranslation()
        }
      }

    if let translation = viewModel.translation, !viewModel.isLoadingTranslation, preferences.preferredTranslationType != .useApple {
      GroupBox {
        VStack(alignment: .leading, spacing: 4) {
          Text(translation.content.asSafeMarkdownAttributedString)
            .font(.scaledBody)
          Text(getLocalizedString(langCode: translation.detectedSourceLanguage, provider: translation.provider))
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
      }
      .fixedSize(horizontal: false, vertical: true)
    }
  }
}
