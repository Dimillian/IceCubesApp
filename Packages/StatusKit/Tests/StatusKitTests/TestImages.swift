import UIKit

func makeOpaqueTestImage(size: Int = 4096) -> UIImage {
  let width = size
  let height = size
  let colorSpace = CGColorSpaceCreateDeviceRGB()
  let bitmapInfo = CGImageAlphaInfo.noneSkipLast.rawValue
  let context = CGContext(
    data: nil,
    width: width,
    height: height,
    bitsPerComponent: 8,
    bytesPerRow: 0,
    space: colorSpace,
    bitmapInfo: bitmapInfo
  )!
  context.setFillColor(UIColor.red.cgColor)
  context.fill(CGRect(x: 0, y: 0, width: width, height: height))
  let cgImage = context.makeImage()!
  return UIImage(cgImage: cgImage)
}
