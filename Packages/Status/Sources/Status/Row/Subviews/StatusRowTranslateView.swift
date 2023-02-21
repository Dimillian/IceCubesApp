import DesignSystem
import Env
import Models
import SwiftUI

struct StatusRowTranslateView: View {
  @Environment(\.isInCaptureMode) private var isInCaptureMode: Bool
  
  @EnvironmentObject private var preferences: UserPreferences

  let status: AnyStatus
  @ObservedObject var viewModel: StatusRowViewModel

  private var shouldShowTranslateButton: Bool {
    let statusLang = viewModel.getStatusLang()

    if let userLang = preferences.serverPreferences?.postLanguage,
       preferences.showTranslateButton,
       !status.content.asRawText.isEmpty,
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
    
  var body: some View {
    if !isInCaptureMode,
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

    if let translation = viewModel.translation, !viewModel.isLoadingTranslation {
      GroupBox {
        VStack(alignment: .leading, spacing: 4) {
          Text(translation.content.asSafeMarkdownAttributedString)
            .font(.scaledBody)
            Text(getLocalizedString(langCode: translation.detectedSourceLanguage, provider: translation.provider))
            .font(.footnote)
            .foregroundColor(.gray)
        }
      }
      .fixedSize(horizontal: false, vertical: true)
    }
  }
}
