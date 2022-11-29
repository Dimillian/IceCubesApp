import Foundation
import SwiftUI

public enum RouteurDestinations: Hashable {
  case accountDetail(id: String)
  case statusDetail(id: String)
}

public class RouterPath: ObservableObject {
  @Published public var path: [RouteurDestinations] = []
  
  public init() {}
  
  public func navigate(to: RouteurDestinations) {
    path.append(to)
  }
}
