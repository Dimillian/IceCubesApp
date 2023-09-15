import CoreHaptics
import UIKit

@MainActor
public class HapticManager {
  public static let shared: HapticManager = .init()

  public enum HapticType {
    case buttonPress
    case dataRefresh(intensity: CGFloat)
    case notification(_ type: UINotificationFeedbackGenerator.FeedbackType)
    case tabSelection
    case timeline
  }

  private let selectionGenerator = UISelectionFeedbackGenerator()
  private let impactGenerator = UIImpactFeedbackGenerator(style: .heavy)
  private let notificationGenerator = UINotificationFeedbackGenerator()

  private let userPreferences = UserPreferences.shared

  private init() {
    selectionGenerator.prepare()
    impactGenerator.prepare()
  }

  @MainActor
  public func fireHaptic(of type: HapticType) {
    guard supportsHaptics else { return }

    switch type {
    case .buttonPress:
      if userPreferences.hapticButtonPressEnabled {
        impactGenerator.impactOccurred()
      }
    case let .dataRefresh(intensity):
      if userPreferences.hapticTimelineEnabled {
        impactGenerator.impactOccurred(intensity: intensity)
      }
    case let .notification(type):
      if userPreferences.hapticButtonPressEnabled {
        notificationGenerator.notificationOccurred(type)
      }
    case .tabSelection:
      if userPreferences.hapticTabSelectionEnabled {
        selectionGenerator.selectionChanged()
      }
    case .timeline:
      if userPreferences.hapticTimelineEnabled {
        selectionGenerator.selectionChanged()
      }
    }
  }

  public var supportsHaptics: Bool {
    CHHapticEngine.capabilitiesForHardware().supportsHaptics
  }
}
