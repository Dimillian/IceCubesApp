import SwiftUI

public let availableTabBarIconSets: [any TabBarIconSet] =
  [BasicIcons(), FancyIcons()]

public protocol TabBarIconSet {
  var id: IconSetId { get }
  var name: IconSetName { get }
  var tabIcon: [String:String] { get }
}

public enum IconSetId: String {
  case basic = "0"
  case fancy = "1"
}

public enum IconSetName: String {
  case basic = "Basic"
  case fancy = "Fancy"
}

public struct BasicIcons: TabBarIconSet {
  public var id: IconSetId = .basic
  public var name: IconSetName = .basic

  public var tabIcon: [String:String] = [
    "timeline": "rectangle.stack",
    "trending": "chart.line.uptrend.xyaxis",
    "local": "person.2",
    "federated": "globe.americas",
    "notifications": "bell",
    "mentions": "at",
    "explore": "magnifyingglass",
    "messages": "tray",
    "settings": "gear",
    "profile": "person.crop.circle"
  ]
  
  public init() {}
}

public struct FancyIcons: TabBarIconSet {
  public var id: IconSetId = .fancy
  public var name: IconSetName = .fancy

  public var tabIcon: [String:String] = [
      "timeline": "mail.stack",
      "trending": "chart.line.uptrend.xyaxis",
      "local": "person.2",
      "federated": "globe.americas",
      "notifications": "bell",
      "mentions": "at",
      "explore": "magnifyingglass",
      "messages": "tray",
      "settings": "gear",
      "profile": "person.crop.circle"
    ]

  public init() {}
}
