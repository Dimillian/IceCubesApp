import DesignSystem
import Env
import Models
import SwiftUI

@MainActor
struct StatusActionButton: View {
  let configuration: StatusRowActionsView.ActionButtonConfiguration
  let statusDataController: StatusDataController
  let status: Status
  let quoteStatus: any AnyStatus
  let theme: Theme
  let isFocused: Bool
  let isNarrow: Bool
  let isRemoteStatus: Bool
  let privateBoost: Bool
  let isDisabled: Bool
  let handleAction: (StatusRowActionsView.Action) -> Void

  var isQuoteDisabled: Bool {
    quoteStatus.quoteApproval?.currentUser == .denied || quoteStatus.visibility != .pub
  }

  var body: some View {
    actionView
      #if os(visionOS)
        .buttonStyle(.borderless)
        .foregroundColor(Color(UIColor.secondaryLabel))
      #else
        .buttonStyle(
          .statusAction(
            isOn: configuration.display.isOn(dataController: statusDataController),
            tintColor: configuration.display.tintColor(theme: theme)
          )
        )
        .offset(x: -8)
      #endif
      .disabled(isDisabled)
      .opacity(isDisabled ? 0.35 : 1)
      .accessibilityElement(children: .combine)
      .accessibilityLabel(
        configuration.display.accessibilityLabel(
          dataController: statusDataController,
          privateBoost: privateBoost))
  }

  @ViewBuilder
  private var actionView: some View {
    if configuration.showsMenu && configuration.trigger == .boost {
      Menu {
        Button {
          handleAction(.boost)
        } label: {
          Label("status.action.boost", systemImage: "arrow.2.squarepath")
            .tint(theme.labelColor)
        }
        Button {
          handleAction(.quote)
        } label: {
          Label("Quote", systemImage: isQuoteDisabled ? "pencil.slash" : "quote.bubble")
            .tint(theme.labelColor)
          if isQuoteDisabled {
            Text("You are not allowed to quote this post")
          }
        }
        .disabled(isQuoteDisabled)
        .opacity(isQuoteDisabled ? 0.35 : 1)
      } label: {
        HStack(spacing: 2) {
          actionImage(for: configuration.display)
          if let count = countValue {
            countView(count)
          }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .contentShape(Rectangle())
      }
    } else {
      Button {
        handleAction(configuration.trigger)
      } label: {
        HStack(spacing: 2) {
          actionImage(for: configuration.display)
          if let count = countValue {
            countView(count)
          }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .contentShape(Rectangle())
      }
    }
  }

  @ViewBuilder
  private func actionImage(for action: StatusRowActionsView.Action) -> some View {
    action
      .image(dataController: statusDataController, privateBoost: privateBoost)
      #if targetEnvironment(macCatalyst)
        .font(.scaledBody)
      #else
        .font(.body)
        .dynamicTypeSize(.large)
      #endif
  }

  private var countValue: Int? {
    guard !isNarrow, !isRemoteStatus else { return nil }
    return configuration.display.count(
      dataController: statusDataController,
      isFocused: isFocused,
      theme: theme)
  }

  private func countView(_ count: Int) -> some View {
    Text(count, format: .number.notation(.compactName))
      .lineLimit(1)
      .minimumScaleFactor(0.6)
      .contentTransition(.numericText(value: Double(count)))
      .foregroundColor(Color(UIColor.secondaryLabel))
      #if targetEnvironment(macCatalyst)
        .font(.scaledFootnote)
      #else
        .font(.footnote)
        .dynamicTypeSize(.medium)
      #endif
      .monospacedDigit()
      .opacity(count > 0 ? 1 : 0)
  }
}
