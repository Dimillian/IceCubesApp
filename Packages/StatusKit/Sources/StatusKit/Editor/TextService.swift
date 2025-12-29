import DesignSystem
import Env
import Models
import SwiftUI
import UIKit

extension StatusEditor {
  @MainActor
  struct TextService {
    typealias Mode = StatusEditor.ViewModel.Mode

    struct InitialTextChanges {
      var statusText: NSMutableAttributedString?
      var selectedRange: NSRange?
      var mentionString: String?
      var spoilerOn: Bool?
      var spoilerText: String?
      var visibility: Models.Visibility?
      var replyToStatus: Status?
      var embeddedStatus: Status?
    }

    struct TextUpdate {
      var text: NSMutableAttributedString
      var selection: NSRange
    }

    struct TextProcessingResult: Equatable {
      var urlLengthAdjustments: Int
      var suggestionRange: NSRange?
      var action: TextSuggestionAction
      var didProcess: Bool
    }

    enum TextSuggestionAction: Equatable {
      case suggest(query: String)
      case reset
      case none
    }

    private let maxLengthOfUrl = 23

    func initialTextChanges(
      for mode: Mode,
      currentAccount: Account?,
      currentInstance: CurrentInstance?
    ) -> InitialTextChanges {
      switch mode {
      case .new(let text, let visibility):
        if let text {
          return InitialTextChanges(
            statusText: .init(string: text),
            selectedRange: trailingSelection(for: text),
            mentionString: nil,
            spoilerOn: nil,
            spoilerText: nil,
            visibility: visibility,
            replyToStatus: nil,
            embeddedStatus: nil
          )
        }
        return InitialTextChanges(
          statusText: nil,
          selectedRange: nil,
          mentionString: nil,
          spoilerOn: nil,
          spoilerText: nil,
          visibility: visibility,
          replyToStatus: nil,
          embeddedStatus: nil
        )
      case .shareExtension:
        return InitialTextChanges(
          statusText: nil,
          selectedRange: nil,
          mentionString: nil,
          spoilerOn: nil,
          spoilerText: nil,
          visibility: .pub,
          replyToStatus: nil,
          embeddedStatus: nil
        )
      case .imageURL(_, let caption, _, let visibility):
        if let caption, !caption.isEmpty {
          return InitialTextChanges(
            statusText: .init(string: caption),
            selectedRange: trailingSelection(for: caption),
            mentionString: nil,
            spoilerOn: nil,
            spoilerText: nil,
            visibility: visibility,
            replyToStatus: nil,
            embeddedStatus: nil
          )
        }
        return InitialTextChanges(
          statusText: nil,
          selectedRange: nil,
          mentionString: nil,
          spoilerOn: nil,
          spoilerText: nil,
          visibility: visibility,
          replyToStatus: nil,
          embeddedStatus: nil
        )
      case .replyTo(let status):
        let mention = replyMentionText(for: status, currentAccount: currentAccount)
        let trimmedMention = mention.isEmpty
          ? nil
          : mention.trimmingCharacters(in: .whitespaces)
        return InitialTextChanges(
          statusText: .init(string: mention),
          selectedRange: trailingSelection(for: mention),
          mentionString: trimmedMention,
          spoilerOn: !status.spoilerText.asRawText.isEmpty,
          spoilerText: status.spoilerText.asRawText,
          visibility: UserPreferences.shared.getReplyVisibility(of: status),
          replyToStatus: status,
          embeddedStatus: nil
        )
      case .mention(let account, let visibility):
        let mention = "@\(account.acct) "
        return InitialTextChanges(
          statusText: .init(string: mention),
          selectedRange: trailingSelection(for: mention),
          mentionString: nil,
          spoilerOn: nil,
          spoilerText: nil,
          visibility: visibility,
          replyToStatus: nil,
          embeddedStatus: nil
        )
      case .edit(let status):
        let normalizedText = editText(for: status)
        return InitialTextChanges(
          statusText: .init(string: normalizedText),
          selectedRange: trailingSelection(for: normalizedText),
          mentionString: nil,
          spoilerOn: !status.spoilerText.asRawText.isEmpty,
          spoilerText: status.spoilerText.asRawText,
          visibility: status.visibility,
          replyToStatus: nil,
          embeddedStatus: nil
        )
      case .quote(let status):
        if currentInstance?.isQuoteSupported == true {
          return InitialTextChanges(
            statusText: nil,
            selectedRange: nil,
            mentionString: nil,
            spoilerOn: nil,
            spoilerText: nil,
            visibility: nil,
            replyToStatus: nil,
            embeddedStatus: status
          )
        }
        let quoteText = legacyQuoteText(for: status)
        guard !quoteText.isEmpty else {
          return InitialTextChanges(
            statusText: nil,
            selectedRange: nil,
            mentionString: nil,
            spoilerOn: nil,
            spoilerText: nil,
            visibility: nil,
            replyToStatus: nil,
            embeddedStatus: status
          )
        }
        return InitialTextChanges(
          statusText: .init(string: quoteText),
          selectedRange: NSRange(location: 0, length: 0),
          mentionString: nil,
          spoilerOn: nil,
          spoilerText: nil,
          visibility: nil,
          replyToStatus: nil,
          embeddedStatus: status
        )
      case .quoteLink(let link):
        let text = "\n\n\(link)"
        return InitialTextChanges(
          statusText: .init(string: text),
          selectedRange: NSRange(location: 0, length: 0),
          mentionString: nil,
          spoilerOn: nil,
          spoilerText: nil,
          visibility: nil,
          replyToStatus: nil,
          embeddedStatus: nil
        )
      }
    }

    func insertText(
      _ text: String,
      into statusText: NSMutableAttributedString,
      selection: NSRange
    ) -> TextUpdate {
      let updatedText = NSMutableAttributedString(attributedString: statusText)
      updatedText.mutableString.insert(text, at: selection.location)
      let updatedSelection = NSRange(location: selection.location + text.utf16.count, length: 0)
      return TextUpdate(text: updatedText, selection: updatedSelection)
    }

    func replaceText(
      with text: String,
      in statusText: NSMutableAttributedString,
      range: NSRange
    ) -> TextUpdate {
      let updatedText = NSMutableAttributedString(attributedString: statusText)
      updatedText.mutableString.deleteCharacters(in: range)
      updatedText.mutableString.insert(text, at: range.location)
      let updatedSelection = NSRange(location: range.location + text.utf16.count, length: 0)
      return TextUpdate(text: updatedText, selection: updatedSelection)
    }

    func replaceText(with text: String) -> TextUpdate {
      TextUpdate(text: .init(string: text), selection: trailingSelection(for: text))
    }

    func processText(
      _ text: NSMutableAttributedString,
      theme: Theme?,
      selectedRange: NSRange,
      hasMarkedText: Bool,
      previousUrlLengthAdjustments: Int
    ) -> TextProcessingResult {
      guard !hasMarkedText else {
        return TextProcessingResult(
          urlLengthAdjustments: previousUrlLengthAdjustments,
          suggestionRange: nil,
          action: .none,
          didProcess: false
        )
      }

      applyBaseAttributes(to: text)

      let textValue = text.string
      let allRange = NSRange(location: 0, length: textValue.utf16.count)
      let ranges = hashtagRanges(in: textValue, range: allRange)
        + mentionRanges(in: textValue, range: allRange)

      let tintColor = UIColor(theme?.tintColor ?? .brand)
      applyHighlightAttributes(to: text, ranges: ranges, tintColor: tintColor)

      let suggestion = suggestionAction(
        for: ranges,
        text: textValue,
        selectedRange: selectedRange
      )

      let urlRanges = urlRanges(in: textValue, range: allRange)
      let urlLengthAdjustments = applyURLAttributes(
        to: text,
        ranges: urlRanges,
        tintColor: tintColor
      )

      removeLinkAttributes(from: text, range: allRange)

      return TextProcessingResult(
        urlLengthAdjustments: urlLengthAdjustments,
        suggestionRange: suggestion.range,
        action: suggestion.action,
        didProcess: true
      )
    }

    private func applyBaseAttributes(to text: NSMutableAttributedString) {
      let range = NSRange(location: 0, length: text.string.utf16.count)
      text.addAttributes(
        [
          .foregroundColor: UIColor(Theme.shared.labelColor),
          .font: Font.scaledBodyUIFont,
          .backgroundColor: UIColor.clear,
          .underlineColor: UIColor.clear,
        ],
        range: range
      )
    }

    private func hashtagRanges(in text: String, range: NSRange) -> [NSRange] {
      matchRanges(using: "(#+[\\w0-9(_)]{0,})", text: text, range: range)
    }

    private func mentionRanges(in text: String, range: NSRange) -> [NSRange] {
      matchRanges(using: "(@+[a-zA-Z0-9(_).-]{1,})", text: text, range: range)
    }

    private func urlRanges(in text: String, range: NSRange) -> [NSRange] {
      matchRanges(using: "(?i)https?://(?:www\\.)?\\S+(?:/|\\b)", text: text, range: range)
    }

    private func matchRanges(using pattern: String, text: String, range: NSRange) -> [NSRange] {
      guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return [] }
      return regex.matches(in: text, options: [], range: range).map(\.range)
    }

    private func applyHighlightAttributes(
      to text: NSMutableAttributedString,
      ranges: [NSRange],
      tintColor: UIColor
    ) {
      for range in ranges {
        text.addAttributes([.foregroundColor: tintColor], range: range)
      }
    }

    private func suggestionAction(
      for ranges: [NSRange],
      text: String,
      selectedRange: NSRange
    ) -> (action: TextSuggestionAction, range: NSRange?) {
      guard !ranges.isEmpty else {
        return (.reset, nil)
      }

      for range in ranges {
        guard selectedRange.location == (range.location + range.length),
          let swiftRange = Range(range, in: text)
        else {
          continue
        }
        let query = String(text[swiftRange])
        return (.suggest(query: query), range)
      }

      return (.reset, nil)
    }

    private func applyURLAttributes(
      to text: NSMutableAttributedString,
      ranges: [NSRange],
      tintColor: UIColor
    ) -> Int {
      var totalUrlLength = 0

      for range in ranges {
        totalUrlLength += range.length
        text.addAttributes(
          [
            .foregroundColor: tintColor,
            .underlineStyle: NSUnderlineStyle.single.rawValue,
            .underlineColor: tintColor,
          ],
          range: range
        )
      }

      return totalUrlLength - (maxLengthOfUrl * ranges.count)
    }

    private func removeLinkAttributes(from text: NSMutableAttributedString, range: NSRange) {
      text.enumerateAttributes(in: range) { attributes, range, _ in
        if attributes[.link] != nil {
          text.removeAttribute(.link, range: range)
        }
      }
    }

    private func replyMentionText(for status: Status, currentAccount: Account?) -> String {
      var mentionString = ""
      let author = status.reblog?.account.acct ?? status.account.acct
      if author != currentAccount?.acct {
        mentionString = "@\(author)"
      }

      for mention in status.mentions where mention.acct != currentAccount?.acct {
        if !mentionString.isEmpty {
          mentionString += " "
        }
        mentionString += "@\(mention.acct)"
      }

      if !mentionString.isEmpty {
        mentionString += " "
      }

      return mentionString
    }

    private func editText(for status: Status) -> String {
      var rawText = status.content.asRawText.escape()
      for mention in status.mentions {
        rawText = rawText.replacingOccurrences(of: "@\(mention.username)", with: "@\(mention.acct)")
      }
      return rawText
    }

    private func legacyQuoteText(for status: Status) -> String {
      guard let url = URL(string: status.reblog?.url ?? status.url ?? "") else { return "" }
      let author = status.reblog?.account.acct ?? status.account.acct
      return "\n\nFrom: @\(author)\n\(url)"
    }

    private func trailingSelection(for text: String) -> NSRange {
      NSRange(location: text.utf16.count, length: 0)
    }
  }
}
