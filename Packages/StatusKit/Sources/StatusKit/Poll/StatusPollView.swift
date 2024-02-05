import DesignSystem
import Env
import Models
import Network
import SwiftUI

@MainActor
public struct StatusPollView: View {
  @Environment(Theme.self) private var theme
  @Environment(Client.self) private var client
  @Environment(CurrentInstance.self) private var currentInstance
  @Environment(CurrentAccount.self) private var currentAccount

  @State private var viewModel: StatusPollViewModel

  private var status: AnyStatus

  public init(poll: Poll, status: AnyStatus) {
    _viewModel = .init(initialValue: .init(poll: poll))
    self.status = status
  }

  private func widthForOption(option: Poll.Option, proxy: GeometryProxy) -> CGFloat {
    if viewModel.poll.safeVotersCount != 0 {
      let totalWidth = proxy.frame(in: .local).width
      return totalWidth * ratioForOption(option: option)
    } else {
      return 0
    }
  }

  private func percentForOption(option: Poll.Option) -> Int {
    let percent = ratioForOption(option: option) * 100
    return Int(round(percent))
  }

  private func ratioForOption(option: Poll.Option) -> CGFloat {
    if let votesCount = option.votesCount, viewModel.poll.safeVotersCount != 0 {
      CGFloat(votesCount) / CGFloat(viewModel.poll.safeVotersCount)
    } else {
      0.0
    }
  }

  private func isSelected(option: Poll.Option) -> Bool {
    if let optionIndex = viewModel.poll.options.firstIndex(where: { $0.id == option.id }),
       let _ = viewModel.votes.firstIndex(of: optionIndex)
    {
      return true
    }
    return false
  }

  public var body: some View {
    let isInteractive = viewModel.poll.expired == false && (viewModel.poll.voted ?? true) == false
    VStack(alignment: .leading, spacing: 15) {
      ForEach(Array(viewModel.poll.options.enumerated()), id: \.element.id) { index, option in
        Group {
          if viewModel.showResults {
            VStack {
              HStack {
                Text(option.title)
                Spacer()
                Text("\(percentForOption(option: option))%")
              }
              ProgressView(value: ratioForOption(option: option))
            }
          } else if isSelected(option: option) {
            Button(action: {
              userDidSelectOption(option: option)
            }) {
              HStack {
                Spacer()
                Text(option.title)
                Spacer()
              }
            }
            .buttonStyle(.borderedProminent)
            .clipShape(Capsule())
          } else {
            Button(action: {
              userDidSelectOption(option: option)
            }) {
              HStack {
                Spacer()
                Text(option.title)
                  .foregroundStyle(theme.labelColor)
                  .padding(7)
                Spacer()
              }
              .overlay {
                Capsule()
                  .stroke()
                  .foregroundStyle(.gray)
              }
            }
            .buttonStyle(.plain)
          }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(combinedAccessibilityLabel(for: option, index: index))
        .accessibilityRespondsToUserInteraction(isInteractive)
        .accessibilityAddTraits(isSelected(option: option) ? .isSelected : [])
        .accessibilityAddTraits(isInteractive ? [] : .isStaticText)
        .accessibilityRemoveTraits(isInteractive ? [] : .isButton)
      }
      if !viewModel.poll.expired, !(viewModel.poll.voted ?? false) {
        HStack {
          if !viewModel.votes.isEmpty {
            Button("status.poll.send") {
              Task {
                do {
                  await viewModel.postVotes()
                }
              }
            }
            .buttonStyle(.borderedProminent)
          }
          Button(viewModel.showResults ? "status.poll.hide-results" : "status.poll.show-results") {
            withAnimation {
              viewModel.showResults.toggle()
            }
          }
          .buttonStyle(.bordered)
        }
      }
      footerView

    }.onAppear {
      viewModel.instance = currentInstance.instance
      viewModel.client = client
      Task {
        await viewModel.fetchPoll()
      }
    }
    .accessibilityElement(children: .contain)
    .accessibilityLabel(viewModel.poll.expired ? "accessibility.status.poll.finished.label" : "accessibility.status.poll.active.label")
  }

  private func userDidSelectOption(option: Poll.Option) {
    if !viewModel.poll.expired,
       let index = viewModel.poll.options.firstIndex(where: { $0.id == option.id })
    {
      withAnimation {
        viewModel.handleSelection(index)
      }
    }
  }

  func combinedAccessibilityLabel(for option: Poll.Option, index: Int) -> Text {
    let showPercentage = viewModel.poll.expired || viewModel.poll.voted ?? false
    return Text("accessibility.status.poll.option-prefix-\(index + 1)-of-\(viewModel.poll.options.count)") +
      Text(", ") +
      Text(option.title) +
      Text(showPercentage ? ", \(percentForOption(option: option))%" : "")
  }

  private var footerView: some View {
    HStack(spacing: 0) {
      if viewModel.poll.multiple {
        Text("status.poll.n-votes-voters \(viewModel.poll.votesCount) \(viewModel.poll.safeVotersCount)")
      } else {
        Text("status.poll.n-votes \(viewModel.poll.votesCount)")
      }
      Text(" ⸱ ")
        .accessibilityHidden(true)
      if viewModel.poll.expired {
        Text("status.poll.closed")
      } else if let date = viewModel.poll.expiresAt.value?.asDate {
        Text("status.poll.closes-in \(date, style: .timer)")
      }
    }
    .font(.scaledFootnote)
    .foregroundStyle(.secondary)
    .accessibilityElement(children: .combine)
    .accessibilityAddTraits(.updatesFrequently)
  }
}
