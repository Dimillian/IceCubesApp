import SwiftUI

public struct AppIconPickerView: View {
    @Environment(\.iconController) private var iconController

    public init() {
    }

    @ViewBuilder
    private var currentIcon: some View {
        let iconView = IconView(AppIcon(string: iconController.currentIcon))

        ZStack {
            iconView
                .blur(radius: 20)
                .opacity(0.5)
            iconView
                .clipShape(.rect(cornerRadius: 30))
        }
        .frame(width: 128, height: 128)
        .frame(maxWidth: .infinity, alignment: .center)
    }

    public var body: some View {
        List {
            Section("Current Icon") {
                VStack(alignment: .leading) {
                    currentIcon
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
