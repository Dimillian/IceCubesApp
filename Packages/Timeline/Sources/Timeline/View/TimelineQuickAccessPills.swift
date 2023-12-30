import SwiftUI
import Env
import Models
import DesignSystem

@MainActor
struct TimelineQuickAccessPills: View {
  @Environment(Theme.self) private var theme
  @Environment(CurrentAccount.self) private var currentAccount
  
  @Binding var pinnedFilters: [TimelineFilter]
  @Binding var timeline: TimelineFilter
  
  @State private var draggedFilter: TimelineFilter?
  
  var body: some View {
    ScrollView(.horizontal) {
      HStack {
        ForEach(pinnedFilters) { filter in
          makePill(filter)
        }
      }
    }
    .scrollClipDisabled()
    .scrollIndicators(.never)
    .listRowInsets(EdgeInsets(top: 8, leading: .layoutPadding, bottom: 8, trailing: .layoutPadding))
#if !os(visionOS)
    .listRowBackground(theme.primaryBackgroundColor)
#endif
    .listRowSeparator(.hidden)
  }
  
  @ViewBuilder
  private func makePill(_ filter: TimelineFilter) -> some View {
    if !isFilterSupport(filter) {
      EmptyView()
    } else if filter == timeline {
      makeButton(filter)
        .buttonStyle(.borderedProminent)
    } else {
      makeButton(filter)
        .buttonStyle(.bordered)
    }
  }
  
  private func makeButton(_ filter: TimelineFilter) -> some View {
    Button {
      timeline = filter
    } label: {
      Label(filter.localizedTitle(), systemImage: filter.iconName() ?? "")
        .font(.callout)
    }
    .transition(.push(from: .leading).combined(with: .opacity))
    .onDrag {
      draggedFilter = filter
      return NSItemProvider()
    }
    .onDrop(of: [.text], delegate: PillDropDelegate(destinationItem: filter,
                                                    items: $pinnedFilters,
                                                    draggedItem: $draggedFilter))
  }
  
  private func isFilterSupport(_ filter: TimelineFilter) -> Bool {
    switch filter {
    case .list(let list):
      return currentAccount.lists.contains(where: { $0.id == list.id })
    default:
      return true
    }
  }
}

struct PillDropDelegate: DropDelegate {
  let destinationItem: TimelineFilter
  @Binding var items: [TimelineFilter]
  @Binding var draggedItem: TimelineFilter?
  
  func dropUpdated(info: DropInfo) -> DropProposal? {
    return DropProposal(operation: .move)
  }
  
  func performDrop(info: DropInfo) -> Bool {
    draggedItem = nil
    return true
  }
  
  func dropEntered(info: DropInfo) {
    if let draggedItem {
      let fromIndex = items.firstIndex(of: draggedItem)
      if let fromIndex {
        let toIndex = items.firstIndex(of: destinationItem)
        if let toIndex, fromIndex != toIndex {
          withAnimation {
            self.items.move(fromOffsets: IndexSet(integer: fromIndex), toOffset: (toIndex > fromIndex ? (toIndex + 1) : toIndex))
          }
        }
      }
    }
  }
}
