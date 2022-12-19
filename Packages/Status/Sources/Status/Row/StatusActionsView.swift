import SwiftUI
import Models
import Routeur

struct StatusActionsView: View {
  let status: Status
  
  enum Actions: CaseIterable {
    case respond, boost, favourite, share
    
    var iconName: String {
      switch self {
      case .respond:
        return "bubble.right"
      case .boost:
        return "arrow.left.arrow.right.circle"
      case .favourite:
        return "star"
      case .share:
        return "square.and.arrow.up"
      }
    }
    
    func count(status: Status) -> Int? {
      switch self {
      case .respond:
        return status.repliesCount
      case .favourite:
        return status.favouritesCount
      case .boost:
        return status.reblogsCount
      case .share:
        return nil
      }
    }
  }
  
  var body: some View {
    HStack {
      ForEach(Actions.allCases, id: \.self) { action in
        Button {
          
        } label: {
          HStack(spacing: 2) {
            Image(systemName: action.iconName)
            if let count = action.count(status: status) {
              Text("\(count)")
                .font(.footnote)
            }
          }
        }
        if action != .share {
          Spacer()
        }
      }
    }.tint(.gray)
  }
}
