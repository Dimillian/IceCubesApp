import DesignSystem
import Env
import Models
import SwiftUI
import UIKit

extension StatusEditor {
  @MainActor
  struct TextEditingService {
    private let textService = TextService()

    func insertStatusText(_ text: String, in store: StatusEditor.EditorStore) {
      let update = textService.insertText(
        text,
        into: store.textState.statusText,
        selection: store.selectedRange
      )
      updateStatusText(update.text, selection: update.selection, in: store)
    }

    func replaceText(_ text: String, in range: NSRange, in store: StatusEditor.EditorStore) {
      let update = textService.replaceText(
        with: text,
        in: store.textState.statusText,
        range: range
      )
      updateStatusText(update.text, selection: update.selection, in: store)
      if let textView = store.textView {
        textView.delegate?.textViewDidChange?(textView)
      }
    }

    func replaceText(_ text: String, in store: StatusEditor.EditorStore) {
      let update = textService.replaceText(with: text)
      updateStatusText(update.text, selection: update.selection, in: store)
    }

    func applyTextChanges(
      _ changes: TextService.InitialTextChanges,
      in store: StatusEditor.EditorStore
    ) {
      if let visibility = changes.visibility {
        store.visibility = visibility
      }
      if let replyToStatus = changes.replyToStatus {
        store.replyToStatus = replyToStatus
      }
      if let embeddedStatus = changes.embeddedStatus {
        store.embeddedStatus = embeddedStatus
      }
      if let spoilerOn = changes.spoilerOn {
        store.spoilerOn = spoilerOn
      }
      if let spoilerText = changes.spoilerText {
        store.spoilerText = spoilerText
      }
      store.textState.mentionString = changes.mentionString

      if let statusText = changes.statusText {
        updateStatusText(statusText, selection: changes.selectedRange, in: store)
      } else if let selection = changes.selectedRange {
        store.selectedRange = selection
      }
    }

    func initialTextChanges(
      for mode: StatusEditor.EditorStore.Mode,
      currentAccount: Account?,
      currentInstance: CurrentInstance?,
      preferences: UserPreferences?
    ) -> TextService.InitialTextChanges {
      textService.initialTextChanges(
        for: mode,
        currentAccount: currentAccount,
        currentInstance: currentInstance,
        preferences: preferences
      )
    }

    func updateStatusText(
      _ text: NSMutableAttributedString,
      selection: NSRange? = nil,
      in store: StatusEditor.EditorStore
    ) {
      let resolvedSelection = selection ?? store.selectedRange
      store.textState.statusText = text
      processText(selection: resolvedSelection, in: store)
      checkEmbed(in: store)
      store.textView?.attributedText = store.textState.statusText
      store.selectedRange = resolvedSelection
    }

    private func processText(selection: NSRange, in store: StatusEditor.EditorStore) {
      let result = textService.processText(
        store.textState.statusText,
        theme: store.theme,
        selectedRange: selection,
        hasMarkedText: store.markedTextRange != nil,
        previousUrlLengthAdjustments: store.textState.urlLengthAdjustments
      )
      guard result.didProcess else { return }

      store.textState.urlLengthAdjustments = result.urlLengthAdjustments
      store.textState.currentSuggestionRange = result.suggestionRange

      switch result.action {
      case .suggest(let query):
        store.loadAutoCompleteResults(query: query)
      case .reset:
        store.resetAutoCompletion()
      case .none:
        break
      }
    }

    private func checkEmbed(in store: StatusEditor.EditorStore) {
      if let url = store.embeddedStatusURL,
        store.currentInstance?.isQuoteSupported == false,
        !store.textState.statusText.string.contains(url.absoluteString)
      {
        store.embeddedStatus = nil
        store.mode = .new(text: nil, visibility: store.visibility)
      }
    }
  }
}
