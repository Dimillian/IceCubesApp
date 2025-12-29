import Foundation

extension StatusEditor {
  struct TextState {
    var statusText: NSMutableAttributedString = .init(string: "")
    var mentionString: String?
    var urlLengthAdjustments: Int = 0
    var currentSuggestionRange: NSRange?
    var backupStatusText: NSAttributedString?
  }
}
