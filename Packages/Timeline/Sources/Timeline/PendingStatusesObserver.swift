import Foundation
import SwiftUI
import Models
import DesignSystem
import Combine

@MainActor
class PendingStatusesObserver: ObservableObject {
  @AppStorage("expanded") public var isExpanded: Bool = false
  
  @Published var pendingStatuses: [Status] = []
  
  let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
  var disableUpdate: Bool = false

  func removeStatus(status: Status) {
    if !disableUpdate, let index = pendingStatuses.firstIndex(of: status) {
      pendingStatuses.removeSubrange(index...(pendingStatuses.count - 1))
      feedbackGenerator.impactOccurred()
    }
  }
  
  func getMaxAvatarCountRange() -> Int {
    return pendingStatuses.count >= 4 ? 4 : pendingStatuses.count
  }
  
  func getMoreCount() -> Int? {
    return pendingStatuses.count > 4 ? (pendingStatuses.count - 4) : nil
  }
  
  init() {}
}

struct PendingStatusesObserverView: View {
  private let pendingStatusBoxHeight = 44.0
  @ObservedObject var observer: PendingStatusesObserver
  @State var proxy: ScrollViewProxy
  
  var body: some View {
    if observer.pendingStatuses.count > 0 {
      HStack {
        Spacer()
        HStack {
          Button {
            withAnimation {
              proxy.scrollTo(observer.pendingStatuses.last, anchor: .bottom)
            }
          } label: {
            if observer.isExpanded {
              ForEach(observer.pendingStatuses[0..<observer.getMaxAvatarCountRange()]) { status in
                AvatarView(url: status.account.avatar, size: .badge)
              }
              if let moreCount = observer.getMoreCount() {
                Text("+\(moreCount)")
              }
            } else {
              Text("\(observer.pendingStatuses.count)")
            }
          }
          Menu {
            Button {
              withAnimation {
                observer.isExpanded.toggle()
              }
            } label: {
              Label(observer.isExpanded ? "settings.pendingstatus.shrinked" : "settings.pendingstatus.expanded", systemImage: observer.isExpanded ? "number.circle" : "person.and.arrow.left.and.arrow.right")
            }
          } label: {
            Image(systemName: "ellipsis")
              .resizable()
              .aspectRatio(contentMode: .fit)
              .frame(width: 16, height: 16)
              .rotationEffect(.degrees(90))
          }
          .foregroundColor(.gray)
          .contentShape(Rectangle())
        }
        .padding(8)
        .background(.white)
        .cornerRadius(pendingStatusBoxHeight / 2)
        .frame(height: pendingStatusBoxHeight)
        .shadow(radius: 5)
      }.padding(4)
    }
  }
}
