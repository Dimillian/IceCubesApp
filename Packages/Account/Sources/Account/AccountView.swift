import SwiftUI
import Models

public struct AccountView: View {
  private let accountId: String
  
  public init(accountId: String) {
    self.accountId = accountId
  }
  
  public var body: some View {
    Text("Account id \(accountId)")
  }
}
