import SwiftUI
import Models
import Routeur

struct StatusActionsView: View {
  let status: Status
  
  var body: some View {
    HStack {
      Button {
        
      } label: {
        Image(systemName: "bubble.right")
      }
      Spacer()
      Button {
        
      } label: {
        Image(systemName: "arrow.left.arrow.right.circle")
      }
      Spacer()
      Button {
        
      } label: {
        Image(systemName: "star")
      }
      Spacer()
      Button {
        
      } label: {
        Image(systemName: "square.and.arrow.up")
      }
    }
  }
}
