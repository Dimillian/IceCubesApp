import Combine
import SwiftUI

public class Theme: ObservableObject {
  enum ThemeKey: String {
    case colorScheme, tint, label, primaryBackground, secondaryBackground
    case avatarPosition, avatarShape, statusActionsDisplay, statusDisplayStyle
    case selectedSet, selectedScheme
    case followSystemColorSchme
    case displayFullUsernameTimeline
    case lineSpacing
  }

  public enum FontState: Int, CaseIterable {
    case system
    case openDyslexic
    case hyperLegible
    case SFRounded
    case custom

    @MainActor
    public var title: LocalizedStringKey {
      switch self {
      case .system:
        return "settings.display.font.system"
      case .openDyslexic:
        return "Open Dyslexic"
      case .hyperLegible:
        return "Hyper Legible"
      case .SFRounded:
        return "SF Rounded"
      case .custom:
        return "settings.display.font.custom"
      }
    }
  }

  public enum AvatarPosition: String, CaseIterable {
    case leading, top

    public var description: LocalizedStringKey {
      switch self {
      case .leading:
        return "enum.avatar-position.leading"
      case .top:
        return "enum.avatar-position.top"
      }
    }
  }

  public enum AvatarShape: String, CaseIterable {
    case circle, rounded

    public var description: LocalizedStringKey {
      switch self {
      case .circle:
        return "enum.avatar-shape.circle"
      case .rounded:
        return "enum.avatar-shape.rounded"
      }
    }
  }

  public enum StatusActionsDisplay: String, CaseIterable {
    case full, discret, none

    public var description: LocalizedStringKey {
      switch self {
      case .full:
        return "enum.status-actions-display.all"
      case .discret:
        return "enum.status-actions-display.only-buttons"
      case .none:
        return "enum.status-actions-display.no-buttons"
      }
    }
  }

  public enum StatusDisplayStyle: String, CaseIterable {
    case large, medium, compact

    public var description: LocalizedStringKey {
      switch self {
      case .large:
        return "enum.status-display-style.large"
      case .medium:
        return "enum.status-display-style.medium"
      case .compact:
        return "enum.status-display-style.compact"
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

  @AppStorage("is_previously_set") public var isThemePreviouslySet: Bool = false
  @AppStorage(ThemeKey.selectedScheme.rawValue) public var selectedScheme: ColorScheme = .dark
  @AppStorage(ThemeKey.tint.rawValue) public var tintColor: Color = .black
  @AppStorage(ThemeKey.primaryBackground.rawValue) public var primaryBackgroundColor: Color = .white
  @AppStorage(ThemeKey.secondaryBackground.rawValue) public var secondaryBackgroundColor: Color = .gray
  @AppStorage(ThemeKey.label.rawValue) public var labelColor: Color = .black
  @AppStorage(ThemeKey.avatarPosition.rawValue) var rawAvatarPosition: String = AvatarPosition.top.rawValue
  @AppStorage(ThemeKey.avatarShape.rawValue) var rawAvatarShape: String = AvatarShape.rounded.rawValue
  @AppStorage(ThemeKey.selectedSet.rawValue) var storedSet: ColorSetName = .iceCubeDark
  @AppStorage(ThemeKey.statusActionsDisplay.rawValue) public var statusActionsDisplay: StatusActionsDisplay = .full
  @AppStorage(ThemeKey.statusDisplayStyle.rawValue) public var statusDisplayStyle: StatusDisplayStyle = .large
  @AppStorage(ThemeKey.followSystemColorSchme.rawValue) public var followSystemColorScheme: Bool = true
  @AppStorage(ThemeKey.displayFullUsernameTimeline.rawValue) public var displayFullUsername: Bool = true
  @AppStorage(ThemeKey.lineSpacing.rawValue) public var lineSpacing: Double = 0.8
  @AppStorage("font_size_scale") public var fontSizeScale: Double = 1
  @AppStorage("chosen_font") public private(set) var chosenFontData: Data?

  @Published public var avatarPosition: AvatarPosition = .top
  @Published public var avatarShape: AvatarShape = .rounded
  @Published public var selectedSet: ColorSetName = .iceCubeDark

  private var cancellables = Set<AnyCancellable>()

  public static let shared = Theme()

  private init() {
    selectedSet = storedSet

    avatarPosition = AvatarPosition(rawValue: rawAvatarPosition) ?? .top
    avatarShape = AvatarShape(rawValue: rawAvatarShape) ?? .rounded

    $avatarPosition
      .dropFirst()
      .map(\.rawValue)
      .sink { [weak self] position in
        self?.rawAvatarPosition = position
      }
      .store(in: &cancellables)

    $avatarShape
      .dropFirst()
      .map(\.rawValue)
      .sink { [weak self] shape in
        self?.rawAvatarShape = shape
      }
      .store(in: &cancellables)

    // Workaround, since @AppStorage can't be directly observed
    $selectedSet
      .dropFirst()
      .sink { [weak self] colorSetName in
        self?.setColor(withName: colorSetName)
      }
      .store(in: &cancellables)
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
