import Combine
import SwiftUI

@MainActor
@Observable
public final class Theme {
  final class ThemeStorage {
    enum ThemeKey: String {
      case colorScheme, tint, label, primaryBackground, secondaryBackground
      case avatarPosition2, avatarShape2, statusActionsDisplay, statusDisplayStyle
      case selectedSet, selectedScheme
      case followSystemColorSchme
      case displayFullUsernameTimeline
      case lineSpacing
      case statusActionSecondary
    }

    @AppStorage("is_previously_set") public var isThemePreviouslySet: Bool = false
    @AppStorage(ThemeKey.selectedScheme.rawValue) public var selectedScheme: ColorScheme = .dark
    @AppStorage(ThemeKey.tint.rawValue) public var tintColor: Color = .black
    @AppStorage(ThemeKey.primaryBackground.rawValue) public var primaryBackgroundColor: Color = .white
    @AppStorage(ThemeKey.secondaryBackground.rawValue) public var secondaryBackgroundColor: Color = .gray
    @AppStorage(ThemeKey.label.rawValue) public var labelColor: Color = .black
    @AppStorage(ThemeKey.avatarPosition2.rawValue) var avatarPosition: AvatarPosition = .leading
    @AppStorage(ThemeKey.avatarShape2.rawValue) var avatarShape: AvatarShape = .circle
    @AppStorage(ThemeKey.selectedSet.rawValue) var storedSet: ColorSetName = .iceCubeDark
    @AppStorage(ThemeKey.statusActionsDisplay.rawValue) public var statusActionsDisplay: StatusActionsDisplay = .full
    @AppStorage(ThemeKey.statusDisplayStyle.rawValue) public var statusDisplayStyle: StatusDisplayStyle = .large
    @AppStorage(ThemeKey.followSystemColorSchme.rawValue) public var followSystemColorScheme: Bool = true
    @AppStorage(ThemeKey.displayFullUsernameTimeline.rawValue) public var displayFullUsername: Bool = false
    @AppStorage(ThemeKey.lineSpacing.rawValue) public var lineSpacing: Double = 1.2
    @AppStorage(ThemeKey.statusActionSecondary.rawValue) public var statusActionSecondary: StatusActionSecondary = .share
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

  public enum StatusActionSecondary: String, CaseIterable {
    case share, bookmark

    public var description: LocalizedStringKey {
      switch self {
      case .share:
        "status.action.share-title"
      case .bookmark:
        "status.action.bookmark"
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
      computeContrastingTintColor()
    }
  }

  public var primaryBackgroundColor: Color {
    didSet {
      themeStorage.primaryBackgroundColor = primaryBackgroundColor
      computeContrastingTintColor()
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
      computeContrastingTintColor()
    }
  }

  public private(set) var contrastingTintColor: Color

  // set contrastingTintColor to either labelColor or primaryBackgroundColor, whichever contrasts
  // better against the tintColor
  private func computeContrastingTintColor() {
    func luminance(_ color: Color.Resolved) -> Float {
      return 0.299 * color.red + 0.587 * color.green + 0.114 * color.blue
    }

    let resolvedTintColor = tintColor.resolve(in: .init())
    let resolvedLabelColor = labelColor.resolve(in: .init())
    let resolvedPrimaryBackgroundColor = primaryBackgroundColor.resolve(in: .init())

    let tintLuminance = luminance(resolvedTintColor)
    let labelLuminance = luminance(resolvedLabelColor)
    let primaryBackgroundLuminance = luminance(resolvedPrimaryBackgroundColor)

    if abs(tintLuminance - labelLuminance) > abs(tintLuminance - primaryBackgroundLuminance) {
      contrastingTintColor = labelColor
    } else {
      contrastingTintColor = primaryBackgroundColor
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

  public var statusActionSecondary: StatusActionSecondary {
    didSet {
      themeStorage.statusActionSecondary = statusActionSecondary
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

  public func restoreDefault() {
    applySet(set: themeStorage.selectedScheme == .dark ? .iceCubeDark : .iceCubeLight)
    isThemePreviouslySet = true
    avatarPosition = .leading
    avatarShape = .circle
    storedSet = selectedSet
    statusActionsDisplay = .full
    statusDisplayStyle = .large
    followSystemColorScheme = true
    displayFullUsername = false
    lineSpacing = 1.2
    fontSizeScale = 1
    chosenFontData = nil
    statusActionSecondary = .share
  }

  private init() {
    isThemePreviouslySet = themeStorage.isThemePreviouslySet
    selectedScheme = themeStorage.selectedScheme
    tintColor = themeStorage.tintColor
    primaryBackgroundColor = themeStorage.primaryBackgroundColor
    secondaryBackgroundColor = themeStorage.secondaryBackgroundColor
    labelColor = themeStorage.labelColor
    contrastingTintColor = .red // real work done in computeContrastingTintColor()
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
    statusActionSecondary = themeStorage.statusActionSecondary
    selectedSet = storedSet

    computeContrastingTintColor()
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
      ThreadsLight(),
      ThreadsDark(),
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
