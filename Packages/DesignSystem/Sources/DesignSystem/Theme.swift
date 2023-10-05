import Combine
import SwiftUI

@Observable public class Theme {
  class ThemeStorage {
    enum ThemeKey: String {
      case colorScheme, tint, label, primaryBackground, secondaryBackground
      case avatarPosition2, avatarShape2, statusActionsDisplay, statusDisplayStyle
      case selectedSet, selectedScheme
      case followSystemColorSchme
      case displayFullUsernameTimeline
      case lineSpacing
    }

    @AppStorage("is_previously_set") public var isThemePreviouslySet: Bool = false
    @AppStorage(ThemeKey.selectedScheme.rawValue) public var selectedScheme: ColorScheme = .dark
    @AppStorage(ThemeKey.tint.rawValue) public var tintColor: Color = .black
    @AppStorage(ThemeKey.primaryBackground.rawValue) public var primaryBackgroundColor: Color = .white
    @AppStorage(ThemeKey.secondaryBackground.rawValue) public var secondaryBackgroundColor: Color = .gray
    @AppStorage(ThemeKey.label.rawValue) public var labelColor: Color = .black
    @AppStorage(ThemeKey.avatarPosition2.rawValue) var avatarPosition: AvatarPosition = .top
    @AppStorage(ThemeKey.avatarShape2.rawValue) var avatarShape: AvatarShape = .rounded
    @AppStorage(ThemeKey.selectedSet.rawValue) var storedSet: ColorSetName = .iceCubeDark
    @AppStorage(ThemeKey.statusActionsDisplay.rawValue) public var statusActionsDisplay: StatusActionsDisplay = .full
    @AppStorage(ThemeKey.statusDisplayStyle.rawValue) public var statusDisplayStyle: StatusDisplayStyle = .large
    @AppStorage(ThemeKey.followSystemColorSchme.rawValue) public var followSystemColorScheme: Bool = true
    @AppStorage(ThemeKey.displayFullUsernameTimeline.rawValue) public var displayFullUsername: Bool = true
    @AppStorage(ThemeKey.lineSpacing.rawValue) public var lineSpacing: Double = 0.8
    @AppStorage("font_size_scale") public var fontSizeScale: Double = 1
    @AppStorage("chosen_font") public var chosenFontData: Data?

    init() {}
  }

  public enum FontState: Int, CaseIterable {
    case system
    case openDyslexic
    case hyperLegible
    case SFRounded
    case custom

    public var title: LocalizedStringKey {
      switch self {
      case .system:
        "settings.display.font.system"
      case .openDyslexic:
        "Open Dyslexic"
      case .hyperLegible:
        "Hyper Legible"
      case .SFRounded:
        "SF Rounded"
      case .custom:
        "settings.display.font.custom"
      }
    }
  }

  public enum AvatarPosition: String, CaseIterable {
    case leading, top

    public var description: LocalizedStringKey {
      switch self {
      case .leading:
        "enum.avatar-position.leading"
      case .top:
        "enum.avatar-position.top"
      }
    }
  }

  public enum AvatarShape: String, CaseIterable {
    case circle, rounded

    public var description: LocalizedStringKey {
      switch self {
      case .circle:
        "enum.avatar-shape.circle"
      case .rounded:
        "enum.avatar-shape.rounded"
      }
    }
  }

  public enum StatusActionsDisplay: String, CaseIterable {
    case full, discret, none

    public var description: LocalizedStringKey {
      switch self {
      case .full:
        "enum.status-actions-display.all"
      case .discret:
        "enum.status-actions-display.only-buttons"
      case .none:
        "enum.status-actions-display.no-buttons"
      }
    }
  }

  public enum StatusDisplayStyle: String, CaseIterable {
    case large, medium, compact

    public var description: LocalizedStringKey {
      switch self {
      case .large:
        "enum.status-display-style.large"
      case .medium:
        "enum.status-display-style.medium"
      case .compact:
        "enum.status-display-style.compact"
      }
    }
  }

  private var _cachedChoosenFont: UIFont?
  public var chosenFont: UIFont? {
    get {
      if let _cachedChoosenFont {
        return _cachedChoosenFont
      }
      guard let chosenFontData,
            let font = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIFont.self, from: chosenFontData) else { return nil }

      _cachedChoosenFont = font
      return font
    }
    set {
      if let font = newValue,
         let data = try? NSKeyedArchiver.archivedData(withRootObject: font, requiringSecureCoding: false)
      {
        chosenFontData = data
      } else {
        chosenFontData = nil
      }
      _cachedChoosenFont = nil
    }
  }

  let themeStorage = ThemeStorage()

  public var isThemePreviouslySet: Bool {
    didSet {
      themeStorage.isThemePreviouslySet = isThemePreviouslySet
    }
  }

  public var selectedScheme: ColorScheme {
    didSet {
      themeStorage.selectedScheme = selectedScheme
    }
  }

  public var tintColor: Color {
    didSet {
      themeStorage.tintColor = tintColor
    }
  }

  public var primaryBackgroundColor: Color {
    didSet {
      themeStorage.primaryBackgroundColor = primaryBackgroundColor
    }
  }

  public var secondaryBackgroundColor: Color {
    didSet {
      themeStorage.secondaryBackgroundColor = secondaryBackgroundColor
    }
  }

  public var labelColor: Color {
    didSet {
      themeStorage.labelColor = labelColor
    }
  }

  public var avatarPosition: AvatarPosition {
    didSet {
      themeStorage.avatarPosition = avatarPosition
    }
  }

  public var avatarShape: AvatarShape {
    didSet {
      themeStorage.avatarShape = avatarShape
    }
  }

  private var storedSet: ColorSetName {
    didSet {
      themeStorage.storedSet = storedSet
    }
  }

  public var statusActionsDisplay: StatusActionsDisplay {
    didSet {
      themeStorage.statusActionsDisplay = statusActionsDisplay
    }
  }

  public var statusDisplayStyle: StatusDisplayStyle {
    didSet {
      themeStorage.statusDisplayStyle = statusDisplayStyle
    }
  }

  public var followSystemColorScheme: Bool {
    didSet {
      themeStorage.followSystemColorScheme = followSystemColorScheme
    }
  }

  public var displayFullUsername: Bool {
    didSet {
      themeStorage.displayFullUsername = displayFullUsername
    }
  }

  public var lineSpacing: Double {
    didSet {
      themeStorage.lineSpacing = lineSpacing
    }
  }

  public var fontSizeScale: Double {
    didSet {
      themeStorage.fontSizeScale = fontSizeScale
    }
  }

  public private(set) var chosenFontData: Data? {
    didSet {
      themeStorage.chosenFontData = chosenFontData
    }
  }

  public var selectedSet: ColorSetName = .iceCubeDark

  public static let shared = Theme()

  private init() {
    isThemePreviouslySet = themeStorage.isThemePreviouslySet
    selectedScheme = themeStorage.selectedScheme
    tintColor = themeStorage.tintColor
    primaryBackgroundColor = themeStorage.primaryBackgroundColor
    secondaryBackgroundColor = themeStorage.secondaryBackgroundColor
    labelColor = themeStorage.labelColor
    avatarPosition = themeStorage.avatarPosition
    avatarShape = themeStorage.avatarShape
    storedSet = themeStorage.storedSet
    statusActionsDisplay = themeStorage.statusActionsDisplay
    statusDisplayStyle = themeStorage.statusDisplayStyle
    followSystemColorScheme = themeStorage.followSystemColorScheme
    displayFullUsername = themeStorage.displayFullUsername
    lineSpacing = themeStorage.lineSpacing
    fontSizeScale = themeStorage.fontSizeScale
    chosenFontData = themeStorage.chosenFontData
    selectedSet = storedSet
  }

  public static var allColorSet: [ColorSet] {
    [
      IceCubeDark(),
      IceCubeLight(),
      IceCubeNeonDark(),
      IceCubeNeonLight(),
      DesertDark(),
      DesertLight(),
      NemesisDark(),
      NemesisLight(),
      MediumLight(),
      MediumDark(),
      ConstellationLight(),
      ConstellationDark(),
    ]
  }

  public func applySet(set: ColorSetName) {
    selectedSet = set
    setColor(withName: set)
  }

  public func setColor(withName name: ColorSetName) {
    let colorSet = Theme.allColorSet.filter { $0.name == name }.first ?? IceCubeDark()
    selectedScheme = colorSet.scheme
    tintColor = colorSet.tintColor
    primaryBackgroundColor = colorSet.primaryBackgroundColor
    secondaryBackgroundColor = colorSet.secondaryBackgroundColor
    labelColor = colorSet.labelColor
    storedSet = name
  }
}
