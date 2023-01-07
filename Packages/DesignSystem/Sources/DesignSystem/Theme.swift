import Combine
import SwiftUI

public class Theme: ObservableObject {
  enum ThemeKey: String {
    case colorScheme, tint, label, primaryBackground, secondaryBackground
    case avatarPosition, avatarShape, statusActionsDisplay, statusDisplayStyle
    case selectedSet, selectedScheme
  }
  
  public enum AvatarPosition: String, CaseIterable {
    case leading, top
    
    public var description: LocalizedStringKey {
      switch self {
      case .leading:
        return "Leading"
      case .top:
        return "Top"
      }
    }
  }

  public enum AvatarShape: String, CaseIterable {
    case circle, rounded

    public var description: LocalizedStringKey {
      switch self {
      case .circle:
        return "Circle"
      case .rounded:
        return "Rounded"
      }
    }
  }
  
  public enum StatusActionsDisplay: String, CaseIterable {
    case full, discret, none

    public var description: LocalizedStringKey {
      switch self {
      case .full:
        return "All"
      case .discret:
        return "Only buttons"
      case .none:
        return "No buttons"
      }
    }
  }
  
  public enum StatusDisplayStyle: String, CaseIterable {
    case large, compact

    public var description: LocalizedStringKey {
      switch self {
      case .large:
        return "Large"
      case .compact:
        return "Compact"
      }
    }
  }
  
  @AppStorage("is_previously_set") private var isSet: Bool = false
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

  @Published public var avatarPosition: AvatarPosition = .top
  @Published public var avatarShape: AvatarShape = .rounded
  @Published public var selectedSet: ColorSetName = .iceCubeDark

  private var cancellables = Set<AnyCancellable>()
  
  public init() {
    selectedSet = storedSet
    
    // If theme is never set before set the default store. This should only execute once after install.
    
    if !isSet {
      setColor(withName: .iceCubeDark)
      isSet = true
    }
    
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
      DesertDark(),
      DesertLight(),
      NemesisDark(),
      NemesisLight()
    ]
  }
  
  public func setColor(withName name: ColorSetName) {
    let colorSet = Theme.allColorSet.filter { $0.name == name }.first ?? IceCubeDark()
    self.selectedScheme = colorSet.scheme
    self.tintColor = colorSet.tintColor
    self.primaryBackgroundColor = colorSet.primaryBackgroundColor
    self.secondaryBackgroundColor = colorSet.secondaryBackgroundColor
    self.labelColor = colorSet.labelColor
    self.storedSet = name
  }
}
