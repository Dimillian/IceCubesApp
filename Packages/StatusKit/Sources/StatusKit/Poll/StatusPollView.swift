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

  private func relativePercent(for vote: Int) -> CGFloat {
    let biggestVote = viewModel.poll.options.compactMap { $0.votesCount }.max() ?? 0
    guard biggestVote > 0 else { return 0 }

    return if vote == biggestVote { 100 } else { CGFloat(vote) * 100 / CGFloat(biggestVote) }
  }

  private func absolutePercent(for vote: Int) -> Int {
    let totalVote = viewModel.poll.safeVotersCount
    guard totalVote > 0 else { return 0 }
    return Int(round(CGFloat(vote) * 100 / CGFloat(totalVote)))
  }

  private func isSelected(option: Poll.Option) -> Bool {
    if let optionIndex = viewModel.poll.options.firstIndex(where: { $0.id == option.id }),
       let _ = viewModel.votes.firstIndex(of: optionIndex)
    {
      return true
    }
    return false
  }

  private func buttonImage(option: Poll.Option) -> some View {
    let isSelected = isSelected(option: option)
    var imageName = ""
    if viewModel.poll.multiple {
      if isSelected {
        imageName = "checkmark.square"
      } else {
        imageName = "square"
      }
    } else {
      if isSelected {
        imageName = "record.circle"
      } else {
        imageName = "circle"
      }
    }
    return Image(systemName: imageName)
      .foregroundColor(theme.labelColor)
  }

  public var body: some View {
    let isInteractive = viewModel.poll.expired == false && (viewModel.poll.voted ?? true) == false
    VStack(alignment: .leading) {
      ForEach(Array(viewModel.poll.options.enumerated()), id: \.element.id) { index, option in
        HStack {
          if status.account.id == currentAccount.account?.id {
            makeBarView(for: option, buttonImage: EmptyView())
              .disabled(true)
          } else {
            makeBarView(for: option, buttonImage: buttonImage(option: option))
              .disabled(isInteractive == false)
          }
          if viewModel.showResults || status.account.id == currentAccount.account?.id {
            // Make sure they're all the same width using a ZStack with 100% hiding behind the
            // real percentage.
            Text("100%").hidden().overlay(alignment: .trailing) {
              Text("\(absolutePercent(for: option.votesCount ?? 0))%")
                .font(.scaledSubheadline)
            }
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
            Button("status.poll.send") { Task { await viewModel.postVotes() } }
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
      Task { await viewModel.fetchPoll() }
    }
    .accessibilityElement(children: .contain)
    .accessibilityLabel(viewModel.poll.expired ? "accessibility.status.poll.finished.label" : "accessibility.status.poll.active.label")
  }

  func combinedAccessibilityLabel(for option: Poll.Option, index: Int) -> Text {
    let showPercentage = viewModel.poll.expired || viewModel.poll.voted ?? false
    return Text("accessibility.status.poll.option-prefix-\(index + 1)-of-\(viewModel.poll.options.count)") +
      Text(", ") +
      Text(option.title) +
      Text(showPercentage ? ", \(absolutePercent(for: option.votesCount ?? 0))%" : "")
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

  @ViewBuilder
  private func makeBarView(for option: Poll.Option, buttonImage: some View) -> some View {
    Button {
      if !viewModel.poll.expired,
         let index = viewModel.poll.options.firstIndex(where: { $0.id == option.id })
      {
        withAnimation {
          viewModel.handleSelection(index)
        }
      }
    } label: {
      buttonImage
      Spacer()

      HStack {
        Text(option.title)
          .multilineTextAlignment(.leading)
          .foregroundColor(theme.labelColor)
          .font(.scaledBody)
          .lineLimit(3)
          .minimumScaleFactor(0.7)
        Spacer()
      }
      .padding(EdgeInsets(top: 5, leading: 10, bottom: 5, trailing: 10))
      .background(alignment: .leading) {
        if viewModel.showResults || status.account.id == currentAccount.account?.id {
          _PercentWidthLayout(percent: relativePercent(for: option.votesCount ?? 0)) {
            RoundedRectangle(cornerRadius: 10).foregroundColor(theme.tintColor)
              .transition(.asymmetric(insertion: .push(from: .leading),
                                      removal: .push(from: .trailing)))
          }
        }
      }
      .background { RoundedRectangle(cornerRadius: 10).fill(theme.tintColor.opacity(0.4)) }
      .clipShape(RoundedRectangle(cornerRadius: 10))
    }
    .buttonStyle(.borderless)
    .frame(minHeight: .pollBarHeight)
  }

  private struct _PercentWidthLayout: Layout {
    let percent: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache _: inout ()) -> CGSize {
      guard let view = subviews.first else { return CGSize.zero }
      return view.sizeThatFits(proposal)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache _: inout ()) {
      guard let view = subviews.first,
            let width = proposal.width
      else { return }

      view.place(
        at: bounds.origin,
        proposal: ProposedViewSize(width: percent / 100 * width, height: proposal.height)
      )
    }
  }
}
