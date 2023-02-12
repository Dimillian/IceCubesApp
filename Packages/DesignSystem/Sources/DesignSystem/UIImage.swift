import UIKit

public extension UIImage {
  var roundedImage: UIImage? {
    let rect = CGRect(origin: CGPoint(x: 0, y: 0), size: size)
    UIGraphicsBeginImageContextWithOptions(size, false, 1)
    defer { UIGraphicsEndImageContext() }
    UIBezierPath(
      roundedRect: rect,
      cornerRadius: size.height
    ).addClip()
    draw(in: rect)
    return UIGraphicsGetImageFromCurrentImageContext()
  }
}
