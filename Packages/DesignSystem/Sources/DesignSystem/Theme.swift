import SwiftUI

public class Theme: ObservableObject {
    enum ThemeKey: String {
        case colorScheme, tint, label, primaryBackground, secondaryBackground
    }
    
    @AppStorage("is_previously_set") var isSet: Bool = false
    @AppStorage(ThemeKey.colorScheme.rawValue) public var colorScheme: String = "dark" {
        didSet {
            if colorScheme == "dark" {
                setColor(set: DarkSet())
            } else {
                setColor(set: LightSet())
            }
        }
    }
    @AppStorage(ThemeKey.tint.rawValue) public var tintColor: Color = .black
    @AppStorage(ThemeKey.primaryBackground.rawValue) public var primaryBackgroundColor: Color = .white
    @AppStorage(ThemeKey.secondaryBackground.rawValue) public var secondaryBackgroundColor: Color = .gray
    @AppStorage(ThemeKey.label.rawValue) public var labelColor: Color = .black
    
    public init() {
        
        if !isSet {
            setColor(set: DarkSet())
            isSet.toggle()
        }
    }
    
    public func setColor(set: ColorSet) {
        self.tintColor = set.tintColor
        self.primaryBackgroundColor = set.primaryBackgroundColor
        self.secondaryBackgroundColor = set.secondaryBackgroundColor
        self.labelColor = set.labelColor
    }
}
