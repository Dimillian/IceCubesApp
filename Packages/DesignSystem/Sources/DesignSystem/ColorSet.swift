import SwiftUI
public protocol ColorSet {
  var name: ColorSetName { get }
  var scheme: ColorScheme { get }
  var tintColor: Color { get set }
  var primaryBackgroundColor: Color { get set }
  var secondaryBackgroundColor: Color { get set }
  var labelColor: Color { get set }
}

public enum ColorScheme: String {
  case dark, light
}

public enum ColorSetName: String {
  case iceCubeDark = "Ice Cube - Dark"
  case iceCubeLight = "Ice Cube - Light"
  case desertDark = "Desert - Dark"
  case desertLight = "Desert - Light"
}

public struct IceCubeDark: ColorSet {
  public var name: ColorSetName = .iceCubeDark
  public var scheme: ColorScheme = .dark
  public var tintColor: Color = Color(red: 187/255, green: 59/255, blue: 226/255)
  public var primaryBackgroundColor: Color =  Color(red: 16/255, green: 21/255, blue: 35/255)
  public var secondaryBackgroundColor: Color = Color(red: 30/255, green: 35/255, blue: 62/255)
  public var labelColor: Color = .white
  
  public init() {}
}

public struct IceCubeLight: ColorSet {
  public var name: ColorSetName = .iceCubeLight
  public var scheme: ColorScheme = .light
  public var tintColor: Color = Color(red: 187/255, green: 59/255, blue: 226/255)
  public var primaryBackgroundColor: Color = .white
  public var secondaryBackgroundColor: Color = Color(hex:0xF0F1F2)
  public var labelColor: Color = .black
  
  public init() {}
}

public struct DesertDark: ColorSet {
  public var name: ColorSetName = .desertDark
  public var scheme: ColorScheme = .dark
  public var tintColor: Color = Color(hex: 0xdf915e)
  public var primaryBackgroundColor: Color = Color(hex: 0x433744)
  public var secondaryBackgroundColor: Color = Color(hex:0x654868)
  public var labelColor: Color = .black
  
  public init() {}
}

public struct DesertLight: ColorSet {
  public var name: ColorSetName = .desertLight
  public var scheme: ColorScheme = .light
  public var tintColor: Color = Color(hex: 0xdf915e)
  public var primaryBackgroundColor: Color = Color(hex: 0xfcf2eb)
  public var secondaryBackgroundColor: Color = Color(hex:0xeeede7)
  public var labelColor: Color = .black
  
  public init() {}
}

