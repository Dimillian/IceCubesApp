import DesignSystem
import Env
import Models
import SwiftUI
import UIKit

extension StatusEditor {
  @MainActor
  struct TextEditingService {
    private let textService = TextService()

    func insertStatusText(_ text: String, in viewModel: StatusEditor.ViewModel) {
      let update = textService.insertText(
        text,
        into: viewModel.textState.statusText,
        selection: viewModel.selectedRange
      )
      updateStatusText(update.text, selection: update.selection, in: viewModel)
    }

    func replaceText(_ text: String, in range: NSRange, in viewModel: StatusEditor.ViewModel) {
      let update = textService.replaceText(
        with: text,
        in: viewModel.textState.statusText,
        range: range
      )
      updateStatusText(update.text, selection: update.selection, in: viewModel)
      if let textView = viewModel.textView {
        textView.delegate?.textViewDidChange?(textView)
      }
    }

    func replaceText(_ text: String, in viewModel: StatusEditor.ViewModel) {
      let update = textService.replaceText(with: text)
      updateStatusText(update.text, selection: update.selection, in: viewModel)
    }

    func applyTextChanges(
      _ changes: TextService.InitialTextChanges,
      in viewModel: StatusEditor.ViewModel
    ) {
      if let visibility = changes.visibility {
        viewModel.visibility = visibility
      }
      if let replyToStatus = changes.replyToStatus {
        viewModel.replyToStatus = replyToStatus
      }
      if let embeddedStatus = changes.embeddedStatus {
        viewModel.embeddedStatus = embeddedStatus
      }
      if let spoilerOn = changes.spoilerOn {
        viewModel.spoilerOn = spoilerOn
      }
      if let spoilerText = changes.spoilerText {
        viewModel.spoilerText = spoilerText
      }
      viewModel.textState.mentionString = changes.mentionString

      if let statusText = changes.statusText {
        updateStatusText(statusText, selection: changes.selectedRange, in: viewModel)
      } else if let selection = changes.selectedRange {
        viewModel.selectedRange = selection
      }
    }

    func initialTextChanges(
      for mode: StatusEditor.ViewModel.Mode,
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
      in viewModel: StatusEditor.ViewModel
    ) {
      let resolvedSelection = selection ?? viewModel.selectedRange
      viewModel.textState.statusText = text
      processText(selection: resolvedSelection, in: viewModel)
      checkEmbed(in: viewModel)
      viewModel.textView?.attributedText = viewModel.textState.statusText
      viewModel.selectedRange = resolvedSelection
    }

    private func processText(selection: NSRange, in viewModel: StatusEditor.ViewModel) {
      let result = textService.processText(
        viewModel.textState.statusText,
        theme: viewModel.theme,
        selectedRange: selection,
        hasMarkedText: viewModel.markedTextRange != nil,
        previousUrlLengthAdjustments: viewModel.textState.urlLengthAdjustments
      )
      guard result.didProcess else { return }

      viewModel.textState.urlLengthAdjustments = result.urlLengthAdjustments
      viewModel.textState.currentSuggestionRange = result.suggestionRange

      switch result.action {
      case .suggest(let query):
        viewModel.loadAutoCompleteResults(query: query)
      case .reset:
        viewModel.resetAutoCompletion()
      case .none:
        break
      }
    }

    private func checkEmbed(in viewModel: StatusEditor.ViewModel) {
      if let url = viewModel.embeddedStatusURL,
        viewModel.currentInstance?.isQuoteSupported == false,
        !viewModel.textState.statusText.string.contains(url.absoluteString)
      {
        viewModel.embeddedStatus = nil
        viewModel.mode = .new(text: nil, visibility: viewModel.visibility)
      }
    }
  }
}
