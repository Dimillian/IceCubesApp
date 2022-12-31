import SwiftUI

public protocol ColorSet {
  var tintColor: Color { get set }
  var primaryBackgroundColor: Color { get set }
  var secondaryBackgroundColor: Color { get set }
  var labelColor: Color { get set }
}

public struct DarkSet: ColorSet {
  public var tintColor: Color = Color(red: 187/255, green: 59/255, blue: 226/255)
  public var primaryBackgroundColor: Color =  Color(red: 16/255, green: 21/255, blue: 35/255)
  public var secondaryBackgroundColor: Color = Color(red: 30/255, green: 35/255, blue: 62/255)
  public var labelColor: Color = .white
  
  public init() {}
}

public struct LightSet: ColorSet {
  public var tintColor: Color = Color(red: 187/255, green: 59/255, blue: 226/255)
  public var primaryBackgroundColor: Color = .white
  public var secondaryBackgroundColor: Color = Color(hex:0xF0F1F2)
  public var labelColor: Color = .black
  
  public init() {}
}
