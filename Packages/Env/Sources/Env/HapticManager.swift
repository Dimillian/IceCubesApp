import UIKit

public class HapticManager {
  public static let shared: HapticManager = .init()

  private let selectionGenerator = UISelectionFeedbackGenerator()
  private let impactGenerator = UIImpactFeedbackGenerator(style: .heavy)
  private let notificationGenerator = UINotificationFeedbackGenerator()

  private init() {
    selectionGenerator.prepare()
    impactGenerator.prepare()
  }

  public func selectionChanged() {
    selectionGenerator.selectionChanged()
  }

  public func impact() {
    impactGenerator.impactOccurred()
  }

  public func impact(intensity: CGFloat) {
    impactGenerator.impactOccurred(intensity: intensity)
  }

  public func notification(type: UINotificationFeedbackGenerator.FeedbackType) {
    notificationGenerator.notificationOccurred(type)
  }
}
