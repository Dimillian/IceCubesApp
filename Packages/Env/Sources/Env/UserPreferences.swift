import SwiftUI
import Foundation

public class UserPreferences: ObservableObject {
  @AppStorage("remote_local_timeline") public var remoteLocalTimelines: [String] = []
  @AppStorage("use_in_app_safari") public var useInAppSafari: Bool = true
  
  public init() { }
}
