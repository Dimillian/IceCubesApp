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
  case nemesisDark = "Nemesis - Dark"
  case nemesisLight = "Nemesis - Light"
}

public struct IceCubeDark: ColorSet {
  public var name: ColorSetName = .iceCubeDark
  public var scheme: ColorScheme = .dark
  public var tintColor: Color = .init(red: 187 / 255, green: 59 / 255, blue: 226 / 255)
  public var primaryBackgroundColor: Color = .init(red: 16 / 255, green: 21 / 255, blue: 35 / 255)
  public var secondaryBackgroundColor: Color = .init(red: 30 / 255, green: 35 / 255, blue: 62 / 255)
  public var labelColor: Color = .white

  public init() {}
}

public struct IceCubeLight: ColorSet {
  public var name: ColorSetName = .iceCubeLight
  public var scheme: ColorScheme = .light
  public var tintColor: Color = .init(red: 187 / 255, green: 59 / 255, blue: 226 / 255)
  public var primaryBackgroundColor: Color = .white
  public var secondaryBackgroundColor: Color = .init(hex: 0xF0F1F2)
  public var labelColor: Color = .black

  public init() {}
}

public struct DesertDark: ColorSet {
  public var name: ColorSetName = .desertDark
  public var scheme: ColorScheme = .dark
  public var tintColor: Color = .init(hex: 0xDF915E)
  public var primaryBackgroundColor: Color = .init(hex: 0x433744)
  public var secondaryBackgroundColor: Color = .init(hex: 0x654868)
  public var labelColor: Color = .white

  public init() {}
}

public struct DesertLight: ColorSet {
  public var name: ColorSetName = .desertLight
  public var scheme: ColorScheme = .light
  public var tintColor: Color = .init(hex: 0xDF915E)
  public var primaryBackgroundColor: Color = .init(hex: 0xFCF2EB)
  public var secondaryBackgroundColor: Color = .init(hex: 0xEEEDE7)
  public var labelColor: Color = .black

  public init() {}
}

public struct NemesisDark: ColorSet {
  public var name: ColorSetName = .nemesisDark
  public var scheme: ColorScheme = .dark
  public var tintColor: Color = .init(hex: 0x17A2F2)
  public var primaryBackgroundColor: Color = .init(hex: 0x000000)
  public var secondaryBackgroundColor: Color = .init(hex: 0x151E2B)
  public var labelColor: Color = .white

  public init() {}
}

public struct NemesisLight: ColorSet {
  public var name: ColorSetName = .nemesisLight
  public var scheme: ColorScheme = .light
  public var tintColor: Color = .init(hex: 0x17A2F2)
  public var primaryBackgroundColor: Color = .init(hex: 0xFFFFFF)
  public var secondaryBackgroundColor: Color = .init(hex: 0xE8ECEF)
  public var labelColor: Color = .black

  public init() {}
}
