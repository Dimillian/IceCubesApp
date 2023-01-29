import DesignSystem
import SwiftUI

struct IconSelectorView: View {
  enum Icon: Int, CaseIterable, Identifiable {
    var id: String {
      "\(rawValue)"
    }

    init(string: String) {
      if string == Icon.primary.appIconName {
        self = .primary
      } else {
        self = .init(rawValue: Int(String(string.replacing("AppIconAlternate", with: "")))!)!
      }
    }

    case primary = 0
    case alt1, alt2, alt3, alt4, alt5, alt6, alt7, alt8
    case alt9, alt10, alt11, alt12, alt13, alt14
    case alt15, alt16, alt17, alt18, alt19, alt20, alt21
    case alt22, alt23, alt24
    
    static var officialIcons: [Icon] {
      [.alt1, .alt2, .alt3, .alt4, .alt5, .alt6, .alt7, .alt8,
                                     .alt9, .alt10, .alt11, .alt12, .alt13, .alt14,
                                     .alt15, .alt16, .alt17, .alt18, .alt19]
    }
    
    static var albertKinngIcons: [Icon] {
      [.alt20, .alt21, .alt22, .alt23, .alt24]
    }

    var appIconName: String {
      switch self {
      case .primary:
        return "AppIcon"
      default:
        return "AppIconAlternate\(rawValue)"
      }
    }

    var iconName: String {
      "icon\(rawValue)"
    }
  }

  @EnvironmentObject private var theme: Theme
  @State private var currentIcon = UIApplication.shared.alternateIconName ?? Icon.primary.appIconName

  private let columns = [GridItem(.adaptive(minimum: 125, maximum: 1024))]

  var body: some View {
    ScrollView {
      VStack(alignment: .leading) {
        Section {
          makeIconGridView(icons: Icon.officialIcons)
        } header: {
          Text("Official icons")
            .font(.scaledHeadline)
        }
        
        Section {
          makeIconGridView(icons: Icon.albertKinngIcons)
        } header: {
          Text("Icons by Albert Kinng")
            .font(.scaledHeadline)
        }
      }
      .padding(6)
      .navigationTitle("settings.app.icon.navigation-title")
    }
    .background(theme.primaryBackgroundColor)
  }
  
  private func makeIconGridView(icons: [Icon]) -> some View {
    LazyVGrid(columns: columns, spacing: 6) {
      ForEach(icons) { icon in
        Button {
          currentIcon = icon.appIconName
          if icon.rawValue == Icon.primary.rawValue {
            UIApplication.shared.setAlternateIconName(nil)
          } else {
            UIApplication.shared.setAlternateIconName(icon.appIconName)
          }
        } label: {
          ZStack(alignment: .bottomTrailing) {
            Image(uiImage: .init(named: icon.iconName) ?? .init())
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
      }
    }
  }
}
