import Combine
import SwiftUI

public class Theme: ObservableObject {
  enum ThemeKey: String {
      case colorScheme, tint, label, primaryBackground, secondaryBackground
      case avatarPosition
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
  @AppStorage(ThemeKey.avatarPosition.rawValue) var rawAvatarPosition: String = AvatarPosition.top.rawValue

  @Published public var avatarPosition: AvatarPosition = .top

  private var cancellables = Set<AnyCancellable>()

  public init() {
    if !isSet {
      setColor(set: DarkSet())
      isSet.toggle()
    }

    avatarPosition = AvatarPosition(rawValue: rawAvatarPosition) ?? .top

    $avatarPosition
      .dropFirst()
      .map(\.rawValue)
      .sink { [weak self] position in
        self?.rawAvatarPosition = position
      }
      .store(in: &cancellables)
  }
  
  public func setColor(set: ColorSet) {
    self.tintColor = set.tintColor
    self.primaryBackgroundColor = set.primaryBackgroundColor
    self.secondaryBackgroundColor = set.secondaryBackgroundColor
    self.labelColor = set.labelColor
  }
}
