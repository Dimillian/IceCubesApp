import Combine
import SwiftUI

public class Theme: ObservableObject {
  enum ThemeKey: String {
    case colorScheme, tint, label, primaryBackground, secondaryBackground
    case avatarPosition, avatarShape, statusActionsDisplay, statusDisplayStyle
    case selectedSet, selectedScheme
    case followSystemColorSchme
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
    case large, compact

    public var description: LocalizedStringKey {
      switch self {
      case .large:
        return "enum.status-display-style.large"
      case .compact:
        return "enum.status-display-style.compact"
      }
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
