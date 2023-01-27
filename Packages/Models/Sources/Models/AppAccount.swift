import Foundation
import SwiftUI

public struct AppAccount: Codable, Identifiable, Hashable {
  public let server: String
  public var accountName: String?
  public let oauthToken: OauthToken?

  public var key: String {
    if let oauthToken {
      return "\(server):\(oauthToken.createdAt)"
    } else {
      return "\(server):anonymous"
    }
  }

  public var id: String {
    key
  }

  public init(server: String,
              accountName: String?,
              oauthToken: OauthToken? = nil)
  {
    self.server = server
    self.accountName = accountName
    self.oauthToken = oauthToken
  }
}
