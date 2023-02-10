import UIKit

extension UIImage{
  public var roundedImage: UIImage? {
    let rect = CGRect(origin:CGPoint(x: 0, y: 0), size: self.size)
    UIGraphicsBeginImageContextWithOptions(self.size, false, 1)
    defer { UIGraphicsEndImageContext() }
    UIBezierPath(
      roundedRect: rect,
      cornerRadius: self.size.height
    ).addClip()
    self.draw(in: rect)
    return UIGraphicsGetImageFromCurrentImageContext()
  }
}

