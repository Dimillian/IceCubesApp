import DesignSystem
import SwiftUI

@MainActor
struct IconSelectorView: View {
  enum Icon: Int, CaseIterable, Identifiable {
    var id: String {
      "\(rawValue)"
    }

    init(string: String) {
      if string == "AppIcon" {
        self = .primary
      } else {
        self = .init(rawValue: Int(String(string.replacing("AppIconAlternate", with: "")))!)!
      }
    }

    case primary = 0
    case alt1, alt2, alt3, alt4
    
    // Unused icons.
    case alt5, alt6, alt7, alt8
    case alt9, alt10, alt11, alt12, alt13
    case alt14, alt15, alt17, atl18, alt19
    
    case alt16, alt20, alt21
    case alt22, alt23, alt24, alt25, alt26
    case alt27, alt28, alt29
    case alt30, alt31, alt32, alt33, alt34, alt35, alt36
    case alt37
    case alt38
    case alt39, alt40, alt41, alt42, alt43
    case alt44, alt45
    case alt46, alt47, alt48
    case alt49

    var appIconName: String {
      return "AppIconAlternate\(rawValue)"
    }

    var previewImageName: String {
      return "AppIconAlternate\(rawValue)-image"
    }
  }

  struct IconSelector: Identifiable {
    var id = UUID()
    let title: String
    let icons: [Icon]

    static let items = [
      IconSelector(
        title: "settings.app.icon.official".localized,
        icons: [
          .primary, .alt46, .alt1, .alt3, .alt4
        ]),
      IconSelector(
        title: "\("settings.app.icon.designed-by".localized) Erich Jurgens",
        icons: [
          .alt2
        ]),
      IconSelector(
        title: "\("settings.app.icon.designed-by".localized) Albert Kinng",
        icons: [.alt22, .alt23, .alt24, .alt25, .alt26]),
      IconSelector(
        title: "\("settings.app.icon.designed-by".localized) Dan van Moll",
        icons: [.alt27, .alt28, .alt29]),
      IconSelector(
        title: "\("settings.app.icon.designed-by".localized) Chanhwi Joo (GitHub @te6-in)",
        icons: [.alt30, .alt31, .alt32, .alt33, .alt34, .alt35, .alt36]),
      IconSelector(
        title: "\("settings.app.icon.designed-by".localized) W. Kovács Ágnes (@wildgica)",
        icons: [.alt37]),
      IconSelector(
        title: "\("settings.app.icon.designed-by".localized) Duncan Horne", icons: [.alt38]),
      IconSelector(
        title: "\("settings.app.icon.designed-by".localized) BeAware@social.beaware.live",
        icons: [.alt39, .alt40, .alt41, .alt42, .alt43]),
      IconSelector(
        title: "\("settings.app.icon.designed-by".localized) Simone Margio",
        icons: [.alt44, .alt45]),
      IconSelector(
        title: "\("settings.app.icon.designed-by".localized) Peter Broqvist (@PKB)",
        icons: [.alt47, .alt48]),
      IconSelector(
        title: "\("settings.app.icon.designed-by".localized) Oz Tsori (@oztsori)", icons: [.alt49]),
    ]
  }

  @Environment(Theme.self) private var theme
  @State private var currentIcon =
    UIApplication.shared.alternateIconName ?? Icon.primary.appIconName

  private let columns = [GridItem(.adaptive(minimum: 125, maximum: 1024))]

  var body: some View {
    ScrollView {
      VStack(alignment: .leading) {
        ForEach(IconSelector.items) { item in
          Section {
            makeIconGridView(icons: item.icons)
          } header: {
            Text(item.title)
              .font(.scaledHeadline)
          }
        }
      }
      .padding(6)
      .navigationTitle("settings.app.icon.navigation-title")
    }
    #if !os(visionOS)
      .background(theme.primaryBackgroundColor)
    #endif
  }

  private func makeIconGridView(icons: [Icon]) -> some View {
    LazyVGrid(columns: columns, spacing: 6) {
      ForEach(icons) { icon in
        Button {
          currentIcon = icon.appIconName
          if icon.rawValue == Icon.primary.rawValue {
            UIApplication.shared.setAlternateIconName(nil)
          } else {
            UIApplication.shared.setAlternateIconName(icon.appIconName) { err in
              guard let err else { return }
              assertionFailure("\(err.localizedDescription) - Icon name: \(icon.appIconName)")
            }
          }
        } label: {
          ZStack(alignment: .bottomTrailing) {
            Image(icon.previewImageName)
              .resizable()
              .aspectRatio(contentMode: .fit)
              .frame(minHeight: 125, maxHeight: 1024)
              .cornerRadius(6)
              .shadow(radius: 3)
            if icon.appIconName == currentIcon {
              Image(systemName: "checkmark.seal.fill")
                .padding(4)
                .tint(.green)
            }
          }
        }
        .buttonStyle(.plain)
      }
    }
  }
}

extension String {
  var localized: String {
    NSLocalizedString(self, comment: "")
  }
}
