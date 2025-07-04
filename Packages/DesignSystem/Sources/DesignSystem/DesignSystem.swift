import Foundation

@MainActor
extension CGFloat {
  public static var layoutPadding: CGFloat {
    Theme.shared.compactLayoutPadding ? 20 : 8
  }

  public static let dividerPadding: CGFloat = 2
  public static let scrollToViewHeight: CGFloat = 1
  public static let statusColumnsSpacing: CGFloat = 8
  public static let statusComponentSpacing: CGFloat = 6
  public static let secondaryColumnWidth: CGFloat = 400
  public static let pollBarHeight: CGFloat = 30
}
