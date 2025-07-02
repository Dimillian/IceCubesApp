import Foundation

extension String {
  public func escape() -> String {
    replacingOccurrences(of: "&amp;", with: "&")
      .replacingOccurrences(of: "&lt;", with: "<")
      .replacingOccurrences(of: "&gt;", with: ">")
      .replacingOccurrences(of: "&quot;", with: "\"")
      .replacingOccurrences(of: "&apos;", with: "'")
      .replacingOccurrences(of: "&#39;", with: "’")
  }

  public func URLSafeBase64ToBase64() -> String {
    var base64 = replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
    let countMod4 = count % 4

    if countMod4 != 0 {
      base64.append(String(repeating: "=", count: 4 - countMod4))
    }

    return base64
  }
}
