import SwiftUI
import DesignSystem

@MainActor
class StatusEditorViewModel: ObservableObject {
  @Published var statusText = NSAttributedString(string: "") {
    didSet {
      guard !internalUpdate else { return }
      highlightMeta()
    }
  }
  
  private var internalUpdate: Bool = false
  
  func highlightMeta() {
    let mutableString = NSMutableAttributedString(attributedString: statusText)
    let hashtagPattern = "(#+[a-zA-Z0-9(_)]{1,})"
    let mentionPattern = "(@+[a-zA-Z0-9(_)]{1,})"
    var ranges: [NSRange] = [NSRange]()

    let hashtagRegex = try! NSRegularExpression(pattern: hashtagPattern, options: [])
    let mentionRegex = try! NSRegularExpression(pattern: mentionPattern, options: [])
    ranges = hashtagRegex.matches(in: mutableString.string,
                                  options: [],
                                  range: NSMakeRange(0, mutableString.string.utf8.count)).map {$0.range}
    ranges.append(contentsOf: mentionRegex.matches(in: mutableString.string,
                                                   options: [],
                                                   range: NSMakeRange(0, mutableString.string.utf8.count)).map {$0.range})

    for range in ranges {
      mutableString.addAttributes([.foregroundColor: UIColor(Color.brand)],
                                 range: NSRange(location: range.location, length: range.length))
    }
    internalUpdate = true
    statusText = mutableString
    internalUpdate = false
  }
   
}
