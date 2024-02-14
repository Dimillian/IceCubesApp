import SwiftUI

public let availableColorsSets: [ColorSetCouple] =
  [.init(light: IceCubeLight(), dark: IceCubeDark()),
   .init(light: IceCubeNeonLight(), dark: IceCubeNeonDark()),
   .init(light: DesertLight(), dark: DesertDark()),
   .init(light: NemesisLight(), dark: NemesisDark()),
   .init(light: MediumLight(), dark: MediumDark()),
   .init(light: ConstellationLight(), dark: ConstellationDark()),
   .init(light: ThreadsLight(), dark: ThreadsDark())]

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
  case iceCubeNeonDark = "Ice Cube Neon - Dark"
  case iceCubeNeonLight = "Ice Cube Neon - Light"
  case desertDark = "Desert - Dark"
  case desertLight = "Desert - Light"
  case nemesisDark = "Nemesis - Dark"
  case nemesisLight = "Nemesis - Light"
  case mediumLight = "Medium - Light"
  case mediumDark = "Medium - Dark"
  case constellationLight = "Constellation - Light"
  case constellationDark = "Constellation - Dark"
  case threadsLight = "Threads - Light"
  case threadsDark = "Threads - Dark"
}

public struct ColorSetCouple: Identifiable {
  public var id: String {
    dark.name.rawValue + light.name.rawValue
  }

  public let light: ColorSet
  public let dark: ColorSet
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

public struct IceCubeNeonDark: ColorSet {
  public var name: ColorSetName = .iceCubeNeonDark
  public var scheme: ColorScheme = .dark
  public var tintColor: Color = .init(red: 213 / 255, green: 46 / 255, blue: 245 / 255)
  public var primaryBackgroundColor: Color = .black
  public var secondaryBackgroundColor: Color = .init(red: 19 / 255, green: 0 / 255, blue: 32 / 255)
  public var labelColor: Color = .white

  public init() {}
}

public struct IceCubeNeonLight: ColorSet {
  public var name: ColorSetName = .iceCubeNeonLight
  public var scheme: ColorScheme = .light
  public var tintColor: Color = .init(red: 213 / 255, green: 46 / 255, blue: 245 / 255)
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

public struct MediumDark: ColorSet {
  public var name: ColorSetName = .mediumDark
  public var scheme: ColorScheme = .dark
  public var tintColor: Color = .init(hex: 0x1A8917)
  public var primaryBackgroundColor: Color = .init(hex: 0x121212)
  public var secondaryBackgroundColor: Color = .init(hex: 0x191919)
  public var labelColor: Color = .white

  public init() {}
}

public struct MediumLight: ColorSet {
  public var name: ColorSetName = .mediumLight
  public var scheme: ColorScheme = .light
  public var tintColor: Color = .init(hex: 0x1A8917)
  public var primaryBackgroundColor: Color = .init(hex: 0xFFFFFF)
  public var secondaryBackgroundColor: Color = .init(hex: 0xFAFAFA)
  public var labelColor: Color = .black

  public init() {}
}

public struct ConstellationDark: ColorSet {
  public var name: ColorSetName = .constellationDark
  public var scheme: ColorScheme = .dark
  public var tintColor: Color = .init(hex: 0xFFD966)
  public var primaryBackgroundColor: Color = .init(hex: 0x09192C)
  public var secondaryBackgroundColor: Color = .init(hex: 0x304C7A)
  public var labelColor: Color = .init(hex: 0xE2E4E2)

  public init() {}
}

public struct ConstellationLight: ColorSet {
  public var name: ColorSetName = .constellationLight
  public var scheme: ColorScheme = .light
  public var tintColor: Color = .init(hex: 0xC82238)
  public var primaryBackgroundColor: Color = .init(hex: 0xF4F5F7)
  public var secondaryBackgroundColor: Color = .init(hex: 0xACC7E5)
  public var labelColor: Color = .black

  public init() {}
}

public struct ThreadsDark: ColorSet {
  public var name: ColorSetName = .threadsDark
  public var scheme: ColorScheme = .dark
  public var tintColor: Color = .init(hex: 0x0095F6)
  public var primaryBackgroundColor: Color = .init(hex: 0x101010)
  public var secondaryBackgroundColor: Color = .init(hex: 0x181818)
  public var labelColor: Color = .init(hex: 0xE2E4E2)

  public init() {}
}

public struct ThreadsLight: ColorSet {
  public var name: ColorSetName = .threadsLight
  public var scheme: ColorScheme = .light
  public var tintColor: Color = .init(hex: 0x0095F6)
  public var primaryBackgroundColor: Color = .init(hex: 0xFFFFFF)
  public var secondaryBackgroundColor: Color = .init(hex: 0xFFFFFF)
  public var labelColor: Color = .black

  public init() {}
}
