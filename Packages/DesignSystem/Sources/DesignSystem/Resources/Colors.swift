import SwiftUI

extension Color {
  public static var brand: Color {
    Color(red: 187 / 255, green: 59 / 255, blue: 226 / 255)
  }

  public static var primaryBackground: Color {
    Color(red: 16 / 255, green: 21 / 255, blue: 35 / 255)
  }

  public static var secondaryBackground: Color {
    Color(red: 30 / 255, green: 35 / 255, blue: 62 / 255)
  }

  public static var label: Color {
    Color(.label)
  }
}

extension Color: @retroactive RawRepresentable {
  public init?(rawValue: Int) {
    let red = Double((rawValue & 0xFF0000) >> 16) / 0xFF
    let green = Double((rawValue & 0x00FF00) >> 8) / 0xFF
    let blue = Double(rawValue & 0x0000FF) / 0xFF
    self = Color(red: red, green: green, blue: blue)
  }

  public var rawValue: Int {
    guard let coreImageColor else {
      return 0
    }
    let red = Int(coreImageColor.red * 255 + 0.5)
    let green = Int(coreImageColor.green * 255 + 0.5)
    let blue = Int(coreImageColor.blue * 255 + 0.5)
    return (red << 16) | (green << 8) | blue
  }

  private var coreImageColor: CIColor? {
    CIColor(color: .init(self))
  }
}

extension Color {
  init(hex: Int, opacity: Double = 1.0) {
    let red = Double((hex & 0xFF0000) >> 16) / 255.0
    let green = Double((hex & 0xFF00) >> 8) / 255.0
    let blue = Double((hex & 0xFF) >> 0) / 255.0
    self.init(.sRGB, red: red, green: green, blue: blue, opacity: opacity)
  }
}
