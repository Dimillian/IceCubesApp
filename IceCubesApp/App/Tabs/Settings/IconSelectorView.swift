import SwiftUI

struct IconSelectorView: View {
  enum Icon: String, CaseIterable, Identifiable {
    var id: String {
      self.rawValue
    }
    
    case primary = "AppIconInApp"
    case alternate1 = "AppIconAlternate1"
    case alternate2 = "AppIconAlternate2"
    case alternate3 = "AppIconAlternate3"
    case alternate4 = "AppIconAlternate4"
  }
  
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
                Image(uiImage: .init(named: icon.rawValue) ?? .init())
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
  }
}
