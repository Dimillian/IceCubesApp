import SwiftUI
import Models
import DesignSystem
import Env

struct StatusRowTranslateView: View {
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
  
  var body: some View {
    if let userLang = preferences.serverPreferences?.postLanguage,
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
          if let statusLanguage = viewModel.getStatusLang(),
             let languageName = Locale.current.localizedString(forLanguageCode: statusLanguage)
          {
            Text("status.action.translate-from-\(languageName)")
          } else {
            Text("status.action.translate")
          }
        }
      }
      .buttonStyle(.borderless)
    }

    if let translation = viewModel.translation, !viewModel.isLoadingTranslation {
      GroupBox {
        VStack(alignment: .leading, spacing: 4) {
          Text(translation.content.asSafeMarkdownAttributedString)
            .font(.scaledBody)
          Text("status.action.translated-label-\(translation.provider)")
            .font(.footnote)
            .foregroundColor(.gray)
        }
      }
      .fixedSize(horizontal: false, vertical: true)
    }
  }
}
