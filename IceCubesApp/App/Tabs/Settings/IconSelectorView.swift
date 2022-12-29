import SwiftUI
import DesignSystem

struct IconSelectorView: View {
  enum Icon: String, CaseIterable, Identifiable {
    var id: String {
      self.rawValue
    }
    
    case primary = "AppIcon"
    case alternate1 = "AppIconAlternate1"
    case alternate2 = "AppIconAlternate2"
    case alternate3 = "AppIconAlternate3"
    case alternate4 = "AppIconAlternate4"
    case alternate5 = "AppIconAlternate5"
    case alternate6 = "AppIconAlternate6"
    case alternate7 = "AppIconAlternate7"
    case alternate8 = "AppIconAlternate8"
    case alternate9 = "AppIconAlternate9"
    case alternate10 = "AppIconAlternate10"
    case alternate11 = "AppIconAlternate11"
    case alternate12 = "AppIconAlternate12"
    
    var iconName: String {
      switch self {
      case .primary: return "icon0"
      case .alternate1: return "icon1"
      case .alternate2: return "icon2"
      case .alternate3: return "icon3"
      case .alternate4: return "icon4"
      case .alternate5: return "icon5"
      case .alternate6: return "icon6"
      case .alternate7: return "icon7"
      case .alternate8: return "icon8"
      case .alternate9: return "icon9"
      case .alternate10: return "icon10"
      case .alternate11: return "icon11"
      case .alternate12: return "icon12"
      }
    }
  }
  
  @EnvironmentObject private var theme: Theme
  @State private var currentIcon = UIApplication.shared.alternateIconName ?? Icon.primary.rawValue
  
  private let columns = [GridItem(.adaptive(minimum: 125, maximum: 1024))]
  
  var body: some View {
    ScrollView {
      VStack(alignment: .leading) {
        LazyVGrid(columns: columns, spacing: 6) {
          ForEach(Icon.allCases) { icon in
            Button {
              currentIcon = icon.rawValue
              if icon.rawValue == Icon.primary.rawValue {
                UIApplication.shared.setAlternateIconName(nil)
              } else {
                UIApplication.shared.setAlternateIconName(icon.rawValue)
              }
            } label: {
              ZStack(alignment: .bottomTrailing) {
                Image(uiImage: .init(named: icon.iconName) ?? .init())
                  .resizable()
                  .aspectRatio(contentMode: .fit)
                  .frame(minHeight: 125, maxHeight: 1024)
                  .cornerRadius(6)
                  .shadow(radius: 3)
                if icon.rawValue == currentIcon {
                  Image(systemName: "checkmark.seal.fill")
                    .padding(4)
                    .tint(.green)
                }
              }
            }
          }
        }
      }
      .padding(6)
      .navigationTitle("Icons")
    }
    .background(theme.primaryBackgroundColor)
  }
}
