import SwiftUI

public let availableTabBarIconSets: [any TabBarIconSet] =
  [BasicIcons(),
   FancyIcons(),
   MinimalSquareIcons(),
   NumberedIcons(),
   NumberedSquareIcons(),
   DotsIcons(),
   CreativeIcons(),
   PrettyIcons(),
  ]

public protocol TabBarIconSet {
  var id: IconSetId { get }
  var name: IconSetName { get }
  var tabIcon: [String:String] { get }
}

public enum IconSetId: String {
  case basic = "0"
  case fancy = "1"
  case minimalSquare = "2"
  case numbered = "3"
  case numberedSquare = "4"
  case dots = "5"
  case creative = "6"
  case pretty = "7"
}

public enum IconSetName: String {
  case basic = "Basic"
  case fancy = "Fancy"
  case minimalSquare = "Minimal Square"
  case numbered = "Numbered"
  case numberedSquare = "Numbered Square"
  case dots = "Dots"
  case creative = "Creative"
  case pretty = "Pretty"
}

public struct BasicIcons: TabBarIconSet {
  public var id: IconSetId = .basic
  public var name: IconSetName = .basic

  public var tabIcon: [String:String] = [
    "timeline": "rectangle.stack",
    "notifications": "bell",
    "explore": "magnifyingglass",
    "messages": "tray",
    "profile": "person.crop.circle",
    
    "trending": "chart.line.uptrend.xyaxis",
    "local": "person.2",
    "federated": "globe.americas",
    "mentions": "at",
    "settings": "gear",
  ]
  
  public init() {}
}

public struct FancyIcons: TabBarIconSet {
  public var id: IconSetId = .fancy
  public var name: IconSetName = .fancy

  public var tabIcon: [String:String] = [
      "timeline": "mail.stack",
      "notifications": "bell",
      "explore": "magnifyingglass",
      "messages": "tray",
      "profile": "person.crop.circle",
      
      "trending": "chart.line.uptrend.xyaxis",
      "local": "person.2",
      "federated": "globe.americas",
      "mentions": "at",
      "settings": "gear",
    ]

  public init() {}
}

public struct MinimalSquareIcons: TabBarIconSet {
  public var id: IconSetId = .minimalSquare
  public var name: IconSetName = .minimalSquare

  public var tabIcon: [String:String] = [
      "timeline": "arrowtriangle.backward.square",
      "notifications": "arrowtriangle.backward.square",
      "explore": "arrowtriangle.up.square",
      "messages": "arrowtriangle.right.square",
      "profile": "arrowtriangle.right.square",
      
      "trending": "chart.line.uptrend.xyaxis",
      "local": "person.2",
      "federated": "globe.americas",
      "mentions": "at",
      "settings": "gear",
    ]

  public init() {}
}

public struct NumberedIcons: TabBarIconSet {
  public var id: IconSetId = .numbered
  public var name: IconSetName = .numbered

  public var tabIcon: [String:String] = [
      "timeline": "1.circle",
      "notifications": "2.circle",
      "explore": "3.circle",
      "messages": "4.circle",
      "profile": "5.circle",
      
      "trending": "chart.line.uptrend.xyaxis",
      "local": "person.2",
      "federated": "globe.americas",
      "mentions": "at",
      "settings": "gear",
    ]

  public init() {}
}

public struct NumberedSquareIcons: TabBarIconSet {
  public var id: IconSetId = .numberedSquare
  public var name: IconSetName = .numberedSquare

  public var tabIcon: [String:String] = [
      "timeline": "1.square",
      "notifications": "2.square",
      "explore": "3.square",
      "messages": "4.square",
      "profile": "5.square",
      
      "trending": "chart.line.uptrend.xyaxis",
      "local": "person.2",
      "federated": "globe.americas",
      "mentions": "at",
      "settings": "gear",
    ]

  public init() {}
}

public struct DotsIcons: TabBarIconSet {
  public var id: IconSetId = .dots
  public var name: IconSetName = .dots

  public var tabIcon: [String:String] = [
      "timeline": "aqi.low",
      "notifications": "aqi.medium",
      "explore": "aqi.medium",
      "messages": "aqi.medium",
      "profile": "aqi.low",
      
      "trending": "chart.line.uptrend.xyaxis",
      "local": "person.2",
      "federated": "globe.americas",
      "mentions": "at",
      "settings": "gear",
    ]

  public init() {}
}

public struct CreativeIcons: TabBarIconSet {
  public var id: IconSetId = .creative
  public var name: IconSetName = .creative

  public var tabIcon: [String:String] = [
      "timeline": "camera.filters",
      "notifications": "hourglass.bottomhalf.filled",
      "explore": "circle.hexagongrid.fill",
      "messages": "hand.wave",
      "profile": "crown",
      
      "trending": "chart.line.uptrend.xyaxis",
      "local": "person.2",
      "federated": "globe.americas",
      "mentions": "at",
      "settings": "gear",
    ]

  public init() {}
}

public struct PrettyIcons: TabBarIconSet {
  public var id: IconSetId = .pretty
  public var name: IconSetName = .pretty

  public var tabIcon: [String:String] = [
      "timeline": "camera.filters",
      "notifications": "bolt",
      "explore": "circle.hexagongrid",
      "messages": "paintbrush.pointed",
      "profile": "arkit",
      
      "trending": "chart.line.uptrend.xyaxis",
      "local": "person.2",
      "federated": "globe.americas",
      "mentions": "at",
      "settings": "gear",
    ]

  public init() {}
}
