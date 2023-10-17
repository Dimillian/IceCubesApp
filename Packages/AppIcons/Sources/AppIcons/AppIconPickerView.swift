import SwiftUI

public struct AppIconPickerView: View {
    @Environment(\.iconController) private var iconController

    public init() {
    }

    public var body: some View {
        List {
            Section("Current Icon") {
                VStack(alignment: .leading) {

                    IconView(filename: iconController.currentIcon)
                        .frame(width: 128, height: 128)
                        .background(.black)
                        .clipShape(.rect(cornerRadius: 30))
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden, edges: .all)


            ForEach(IconPack.allCases) { iconPack in
                IconPackGallery(iconPack: iconPack)
            }
        }
        .listStyle(.plain)
        .navigationTitle("App Icon")
    }
}

#Preview {
    AppIconPickerView()
}
