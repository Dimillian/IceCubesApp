import DesignSystem
import Env
import Models
import Network
import SwiftUI

public struct StatusPollView: View {
  @EnvironmentObject private var theme: Theme
  @EnvironmentObject private var client: Client
  @EnvironmentObject private var currentInstance: CurrentInstance
  @EnvironmentObject private var currentAccount: CurrentAccount
  @StateObject private var viewModel: StatusPollViewModel

  private var status: AnyStatus

  public init(poll: Poll, status: AnyStatus) {
    _viewModel = StateObject(wrappedValue: .init(poll: poll))
    self.status = status
  }

  private func widthForOption(option: Poll.Option, proxy: GeometryProxy) -> CGFloat {
    if viewModel.poll.votesCount == 0 {
      return 0
    }
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
    if let optionIndex = viewModel.poll.options.firstIndex(where: { $0.id == option.id }),
       let _ = viewModel.votes.firstIndex(of: optionIndex) {
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
    VStack(alignment: .leading) {
      ForEach(viewModel.poll.options) { option in
        HStack {
          makeBarView(for: option, buttonImage: buttonImage(option: option))
            .disabled(viewModel.poll.expired || (viewModel.poll.voted ?? false))
          if !viewModel.votes.isEmpty || viewModel.poll.expired || status.account.id == currentAccount.account?.id {
            Spacer()
            Text("\(percentForOption(option: option))%")
              .font(.scaledSubheadline)
              .frame(width: 40)
          }
        }
      }
      if !viewModel.poll.expired, !(viewModel.poll.voted ?? false) {
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
  }

  private var footerView: some View {
    HStack(spacing: 0) {
      Text("status.poll.n-votes \(viewModel.poll.votesCount)")
      Text(" ⸱ ")
      if viewModel.poll.expired {
        Text("status.poll.closed")
      } else if let date = viewModel.poll.expiresAt.value?.asDate {
        Text("status.poll.closes-in")
        Text(date, style: .timer)
      }
    }
    .font(.scaledFootnote)
    .foregroundColor(.gray)
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
