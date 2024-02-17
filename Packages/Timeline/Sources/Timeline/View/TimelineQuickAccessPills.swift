import DesignSystem
import Env
import Models
import Network
import SwiftUI

@MainActor
struct TimelineQuickAccessPills: View {
  @Environment(Client.self) private var client
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
    .onChange(of: currentAccount.lists) { _, lists in
      guard client.isAuth else { return }
      var filters = pinnedFilters
      for (index, filter) in filters.enumerated() {
        switch filter {
        case let .list(list):
          if let accountList = lists.first(where: { $0.id == list.id }),
             accountList.title != list.title
          {
            filters[index] = .list(list: accountList)
          }
        default:
          break
        }
      }
      pinnedFilters = filters
    }
  }

  @ViewBuilder
  private func makePill(_ filter: TimelineFilter) -> some View {
    if !isFilterSupported(filter) {
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
      switch filter {
      case .hashtag:
        Label(filter.title.replacingOccurrences(of: "#", with: ""),
              systemImage: filter.iconName())
          .font(.callout)
      case let .list(list):
        if let list = currentAccount.lists.first(where: { $0.id == list.id }) {
          Label(list.title, systemImage: filter.iconName())
            .font(.callout)
        }
      default:
        Label(filter.localizedTitle(), systemImage: filter.iconName())
          .font(.callout)
      }
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

  private func isFilterSupported(_ filter: TimelineFilter) -> Bool {
    switch filter {
    case let .list(list):
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

  func dropUpdated(info _: DropInfo) -> DropProposal? {
    return DropProposal(operation: .move)
  }

  func performDrop(info _: DropInfo) -> Bool {
    draggedItem = nil
    return true
  }

  func dropEntered(info _: DropInfo) {
    if let draggedItem {
      let fromIndex = items.firstIndex(of: draggedItem)
      if let fromIndex {
        let toIndex = items.firstIndex(of: destinationItem)
        if let toIndex, fromIndex != toIndex {
          withAnimation {
            self.items.move(fromOffsets: IndexSet(integer: fromIndex), toOffset: toIndex > fromIndex ? (toIndex + 1) : toIndex)
          }
        }
      }
    }
  }
}
