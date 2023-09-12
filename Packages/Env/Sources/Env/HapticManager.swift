import CoreHaptics
import UIKit

public class HapticManager {
  public static let shared: HapticManager = .init()

  public enum HapticType {
    case buttonPress
    case dataRefresh(intensity: CGFloat)
  #if os(iOS) || targetEnvironment(macCatalyst) || os(tvOS)
    case notification(_ type: UINotificationFeedbackGenerator.FeedbackType)
  #endif
    case tabSelection
    case timeline
  }

  #if os(iOS) || targetEnvironment(macCatalyst) || os(tvOS)
  private let selectionGenerator = UISelectionFeedbackGenerator()
  private let impactGenerator = UIImpactFeedbackGenerator(style: .heavy)
  private let notificationGenerator = UINotificationFeedbackGenerator()
  #endif

  private let userPreferences = UserPreferences.shared

  private init() {
  #if os(iOS) || targetEnvironment(macCatalyst) || os(tvOS)
    selectionGenerator.prepare()
    impactGenerator.prepare()
  #endif
  }

  @MainActor
  public func fireHaptic(of type: HapticType) {
  #if os(iOS) || targetEnvironment(macCatalyst) || os(tvOS)
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
    #endif
  }

  public var supportsHaptics: Bool {
    CHHapticEngine.capabilitiesForHardware().supportsHaptics
  }
}
