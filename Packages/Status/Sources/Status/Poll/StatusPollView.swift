import DesignSystem
import Env
import Models
import Network
import SwiftUI

public struct StatusPollView: View {
  enum Constants {
    static let barHeight: CGFloat = 30
  }

  @EnvironmentObject private var theme: Theme
  @EnvironmentObject private var client: Client
  @EnvironmentObject private var currentInstance: CurrentInstance
  @StateObject private var viewModel: StatusPollViewModel

  public init(poll: Poll) {
    _viewModel = StateObject(wrappedValue: .init(poll: poll))
  }

  private func widthForOption(option: Poll.Option, proxy: GeometryProxy) -> CGFloat {
    let totalWidth = proxy.frame(in: .local).width
    let ratio = CGFloat(option.votesCount) / CGFloat(viewModel.poll.votesCount)
    return totalWidth * ratio
  }

  private func percentForOption(option: Poll.Option) -> Int {
    let ratio = (Float(option.votesCount) / Float(viewModel.poll.votesCount)) * 100
    if ratio.isNaN {
      return 0
    }
    return Int(round(ratio))
  }

  private func isSelected(option: Poll.Option) -> Bool {
    for vote in viewModel.votes {
      return viewModel.poll.options.firstIndex(where: { $0.id == option.id }) == vote
    }
    return false
  }

  public var body: some View {
    VStack(alignment: .leading) {
      ForEach(viewModel.poll.options) { option in
        HStack {
          makeBarView(for: option)
          if !viewModel.votes.isEmpty || viewModel.poll.expired {
            Spacer()
            Text("\(percentForOption(option: option)) %")
              .font(.scaledSubheadline)
              .frame(width: 40)
          }
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
  }

  private var footerView: some View {
    HStack(spacing: 0) {
      Text("status.poll.\(viewModel.poll.votesCount)-votes")
      Text(" ⸱ ")
      if viewModel.poll.expired {
        Text("status.poll.closed")
      } else {
        Text("status.poll.closes-in")
        Text(viewModel.poll.expiresAt.asDate, style: .timer)
      }
    }
    .font(.scaledFootnote)
    .foregroundColor(.gray)
  }

  @ViewBuilder
  private func makeBarView(for option: Poll.Option) -> some View {
    let isSelected = isSelected(option: option)
    Button {
      if !viewModel.poll.expired,
         viewModel.votes.isEmpty,
         let index = viewModel.poll.options.firstIndex(where: { $0.id == option.id })
      {
        withAnimation {
          viewModel.votes.append(index)
          Task {
            await viewModel.postVotes()
          }
        }
      }
    } label: {
      GeometryReader { proxy in
        ZStack(alignment: .leading) {
          Rectangle()
            .background {
              if viewModel.showResults {
                HStack {
                  let width = widthForOption(option: option, proxy: proxy)
                  Rectangle()
                    .foregroundColor(theme.tintColor)
                    .frame(height: Constants.barHeight)
                    .frame(width: width)
                  Spacer()
                }
              }
            }
            .foregroundColor(theme.tintColor.opacity(0.40))
            .frame(height: Constants.barHeight)
            .clipShape(RoundedRectangle(cornerRadius: 8))

          HStack {
            if isSelected {
              Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.mint)
            }
            Text(option.title)
              .foregroundColor(.white)
              .font(.scaledBody)
          }
          .padding(.leading, 12)
        }
      }
      .frame(height: Constants.barHeight)
    }
  }
}
