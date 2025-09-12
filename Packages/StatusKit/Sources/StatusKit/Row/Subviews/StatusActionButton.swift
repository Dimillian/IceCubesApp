import DesignSystem
import Env
import SwiftUI

@MainActor
struct StatusActionButton: View {
  let configuration: StatusRowActionsView.ActionButtonConfiguration
  let statusDataController: StatusDataController
  let theme: Theme
  let isFocused: Bool
  let isNarrow: Bool
  let isRemoteStatus: Bool
  let privateBoost: Bool
  let isDisabled: Bool
  let handleAction: (StatusRowActionsView.Action) -> Void

  var body: some View {
    Button {
      handleAction(configuration.trigger)
    } label: {
      HStack(spacing: 2) {
        actionContent
        if let count = countValue {
          countView(count)
        }
      }
      .padding(.vertical, 6)
      .padding(.horizontal, 8)
      .contentShape(Rectangle())
    }
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
    .accessibilityElement(children: .combine)
    .accessibilityLabel(
      configuration.display.accessibilityLabel(
        dataController: statusDataController,
        privateBoost: privateBoost))
  }

  @ViewBuilder
  private var actionContent: some View {
    if configuration.showsMenu {
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
          Label("Quote", systemImage: "quote.bubble")
            .tint(theme.labelColor)
        }
      } label: {
        actionImage(for: configuration.display)
      }
    } else {
      actionImage(for: configuration.display)
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
