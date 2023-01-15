import DesignSystem
import Env
import SwiftUI

struct StatusEditorPollView: View {
  enum FocusField: Hashable {
    case option(Int)
  }

  @FocusState var focused: FocusField?

  @State private var currentFocusIndex: Int = 0

  @EnvironmentObject private var theme: Theme
  @EnvironmentObject private var currentInstance: CurrentInstance

  @ObservedObject var viewModel: StatusEditorViewModel

  @Binding var showPoll: Bool

  var body: some View {
    let count = viewModel.pollOptions.count

    VStack {
      ForEach(0 ..< count, id: \.self) { index in
        VStack {
          HStack(spacing: 16) {
            TextField("status.poll.option-n \(index + 1)", text: $viewModel.pollOptions[index])
              .textFieldStyle(.roundedBorder)
              .focused($focused, equals: .option(index))
              .onTapGesture {
                if canAddMoreAt(index) {
                  currentFocusIndex = index
                }
              }
              .onSubmit {
                if canAddMoreAt(index) {
                  addChoice(at: index)
                }
              }
              .onChange(of: viewModel.pollOptions[index]) {
                let maxCharacters: Int = currentInstance.instance?.configuration?.polls.maxCharactersPerOption ?? 50
                viewModel.pollOptions[index] = String($0.prefix(maxCharacters))
              }

            if canAddMoreAt(index) {
              Button {
                addChoice(at: index)
              } label: {
                Image(systemName: "plus.circle.fill")
              }
            } else {
              Button {
                removeChoice(at: index)
              } label: {
                Image(systemName: "minus.circle.fill")
              }
            }
          }
          .padding(.horizontal)
          .padding(.top)
        }
      }
      .onAppear {
        focused = .option(0)
      }

      HStack {
        Picker("status.poll.frequency", selection: $viewModel.pollVotingFrequency) {
          ForEach(PollVotingFrequency.allCases, id: \.rawValue) {
            Text($0.displayString)
              .tag($0)
          }
        }
        .layoutPriority(1.0)

        Spacer()

        Picker("status.poll.duration", selection: $viewModel.pollDuration) {
          ForEach(PollDuration.allCases, id: \.rawValue) {
            Text($0.displayString)
              .tag($0)
          }
        }
      }
      .padding(.horizontal)
    }
    .background(
      RoundedRectangle(cornerRadius: 6.0)
        .stroke(theme.secondaryBackgroundColor.opacity(0.6), lineWidth: 1)
        .background(theme.primaryBackgroundColor.opacity(0.3))
    )
  }

  private func addChoice(at index: Int) {
    viewModel.pollOptions.append("")
    currentFocusIndex = index + 1
    moveFocus()
  }

  private func removeChoice(at index: Int) {
    viewModel.pollOptions.remove(at: index)

    if viewModel.pollOptions.count == 1 {
      viewModel.resetPollDefaults()

      withAnimation {
        showPoll = false
      }
    }
  }

  private func moveFocus() {
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
      focused = .option(currentFocusIndex)
    }
  }

  private func canAddMoreAt(_ index: Int) -> Bool {
    let count = viewModel.pollOptions.count
    let maxEntries: Int = currentInstance.instance?.configuration?.polls.maxOptions ?? 4

    return index == count - 1 && count < maxEntries
  }
}
