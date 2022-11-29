import SwiftUI

public struct StatusDetailView: View {
  private let statusId: String
  
  public init(statusId: String) {
    self.statusId = statusId
  }
  
  public var body: some View {
    Text("Status id \(statusId)")
  }
}
