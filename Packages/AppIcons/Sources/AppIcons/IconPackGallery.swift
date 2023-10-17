import SwiftUI

struct IconPackGallery: View {
    @Environment(\.iconController) private var iconController
    @State private var selectedIcon: AppIcon? = nil

    var iconPack: IconPack

    private var numberOfRows: Int {
        let count: Int = iconPack.icons.count

        // Use three rows if there a lot of icons
        if count > 9 {
            return 3
        }

        // Use two rows for smaller sets
        if count > 3 {
            return 2
        }

        // And one row for sets with very few icons.
        return 1
//        iconPack.icons.count > 3 ? 2 : 1
    }

    init(iconPack: IconPack) {
        self.iconPack = iconPack
    }

    var body: some View {
        Section(iconPack.title) {
            scrollView(iconPack.icons)
                .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
        }
        .listRowBackground(Color.clear)
        .listSectionSeparator(.hidden)
        .sheet(item: $selectedIcon) { appIcon in
            IconSelectionConfirmation(icon: appIcon) { selectedIcon in
                iconController.setAppIcon(selectedIcon)
            }
        }
    }

    @ViewBuilder
    func scrollView(_ icons: [AppIcon]) -> some View {
        ScrollView(.horizontal) {
            iconHStack(icons)
        }
//        .scrollTargetBehavior(.viewAligned)
        .contentMargins(12, for: .scrollContent)
    }

    @ViewBuilder
    func iconHStack(_ icons: [AppIcon]) -> some View {
        LazyHGrid(rows: Array(repeating: GridItem(), count: numberOfRows)) {
            ForEach(iconPack.icons) { icon in
                Button {
                    selectedIcon = icon
                } label: {
                    IconView(icon)
                }
                .buttonStyle(.plain)
                .frame(height: 96)
            }
        }
        .scrollTargetLayout()
    }
}

#Preview {
    List {
        IconPackGallery(iconPack: .official)
    }
    .listStyle(.plain)
}
