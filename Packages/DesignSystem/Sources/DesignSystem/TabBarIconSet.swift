import SwiftUI

public let availableTabBarIconSets: [any TabBarIconSet] =
[BasicIcons(),
 TimelinesIcons(),
 ModernIcons(),
 CircleIcons(),
 SquareIcons(),
]

public protocol TabBarIconSet {
  var id: IconSetId { get }
  var name: IconSetName { get }
  var tabIcon: [String:String] { get }
}

public enum IconSetId: String {
  case basic = "0"
  case timelines = "1"
  case modern = "2"
  case circle = "3"
  case square = "4"
}

public enum IconSetName: String {
  case basic = "Default"
  case timelines = "Timelines"
  case modern = "Modern"
  case circle = "Circles"
  case square = "Squares"
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

public struct TimelinesIcons: TabBarIconSet {
  public var id: IconSetId = .timelines
  public var name: IconSetName = .timelines
  
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

public struct ModernIcons: TabBarIconSet {
  public var id: IconSetId = .modern
  public var name: IconSetName = .modern
  
  public var tabIcon: [String:String] = [
    "timeline": "house",
    "notifications": "bell.and.waveform",
    "explore": "binoculars",
    "messages": "ellipsis.message",
    "profile": "person.text.rectangle",
    
    "trending": "chart.line.uptrend.xyaxis",
    "local": "person.2",
    "federated": "globe.americas",
    "mentions": "at",
    "settings": "gear",
  ]
  
  public init() {}
}

public struct CircleIcons: TabBarIconSet {
  public var id: IconSetId = .circle
  public var name: IconSetName = .circle
  
  public var tabIcon: [String:String] = [
    "timeline": "house.circle",
    "notifications": "bell.circle",
    "explore": "chart.line.uptrend.xyaxis.circle",
    "messages": "message.circle",
    "profile": "person.crop.circle",
    
    "trending": "chart.line.uptrend.xyaxis",
    "local": "person.2",
    "federated": "globe.americas",
    "mentions": "at",
    "settings": "gear",
  ]
  
  public init() {}
}

public struct SquareIcons: TabBarIconSet {
  public var id: IconSetId = .square
  public var name: IconSetName = .square
  
  public var tabIcon: [String:String] = [
    "timeline": "app.badge.fill",
    "notifications": "bell.square",
    "explore": "number.square",
    "messages": "mail",
    "profile": "person.crop.square",
    
    "trending": "chart.line.uptrend.xyaxis",
    "local": "person.2",
    "federated": "globe.americas",
    "mentions": "at",
    "settings": "gear",
  ]
  
  public init() {}
}
