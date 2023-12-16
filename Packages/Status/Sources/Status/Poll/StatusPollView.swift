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
          makeBarView(for: option, buttonImage: buttonImage(option: option))
            .disabled(isInteractive == false)
          if viewModel.showResults || status.account.id == currentAccount.account?.id {
            Spacer()
            // Make sure they're all the same width using a ZStack with 100% hiding behind the
            // real percentage.
            ZStack(alignment: .trailing) {
              Text("100%")
                .hidden()

              Text("\(percentForOption(option: option))%")
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
      if !viewModel.poll.expired, !(viewModel.poll.voted ?? false), !viewModel.votes.isEmpty {
        Button("status.poll.send") {
          Task {
            do {
              await viewModel.postVotes()
            }
          }
        }
        .buttonStyle(.bordered)
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
      GeometryReader { proxy in
        ZStack(alignment: .leading) {
          Rectangle()
            .background {
              if viewModel.showResults || status.account.id == currentAccount.account?.id {
                HStack {
                  let width = widthForOption(option: option, proxy: proxy)
                  Rectangle()
                    .foregroundColor(theme.tintColor)
                    .frame(height: .pollBarHeight)
                    .frame(width: width)
                  if width != proxy.size.width {
                    Spacer()
                  }
                }
              }
            }
            .foregroundColor(theme.tintColor.opacity(0.40))
            .frame(height: .pollBarHeight)
            .clipShape(RoundedRectangle(cornerRadius: 8))

          HStack {
            buttonImage
            Text(option.title)
              .foregroundColor(theme.labelColor)
              .font(.scaledBody)
              .minimumScaleFactor(0.7)
          }
          .padding(.leading, 12)
        }
      }
      .frame(height: .pollBarHeight)
    }
    .buttonStyle(.borderless)
  }
}
