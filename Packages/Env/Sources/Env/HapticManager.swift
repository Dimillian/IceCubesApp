import CoreHaptics
import UIKit

public class HapticManager {
  public static let shared: HapticManager = .init()

  public enum HapticType {
    case buttonPress
    case notification(_ type: UINotificationFeedbackGenerator.FeedbackType)
    case dataRefersh(intensity: CGFloat)
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
    case let .dataRefersh(intensity):
      if userPreferences.hapticTimelineEnabled {
        impact(intensity: intensity)
      }
    case .timeline:
      if userPreferences.hapticTimelineEnabled {
        selectionChanged()
      }
    case .tabSelection:
      if userPreferences.hapticTabSelectionEnabled {
        selectionChanged()
      }
    case .buttonPress:
      if userPreferences.hapticButtonPressEnabled {
        impact()
      }
    case let .notification(type):
      if userPreferences.hapticButtonPressEnabled {
        notification(type)
      }
    }
  }

  private func selectionChanged() {
    selectionGenerator.selectionChanged()
  }

  private func impact() {
    impactGenerator.impactOccurred()
  }

  private func impact(intensity: CGFloat) {
    impactGenerator.impactOccurred(intensity: intensity)
  }

  private func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
    notificationGenerator.notificationOccurred(type)
  }

  public var supportsHaptics: Bool {
    CHHapticEngine.capabilitiesForHardware().supportsHaptics
  }
}
