import DesignSystem
import EmojiText
import Env
import Models
import Network
import SwiftUI

@MainActor
public struct ListCreateView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(Theme.self) private var theme
  @Environment(Client.self) private var client
  @Environment(CurrentAccount.self) private var currentAccount

  @State private var title = ""
  @State private var repliesPolicy: Models.List.RepliesPolicy = .list
  @State private var isExclusive: Bool = false
  @State private var isSaving: Bool = false

  public init() {}

  public var body: some View {
    NavigationStack {
      Form {
        Section("lists.edit.settings") {
          TextField("list.edit.title", text: $title)
          Picker("list.edit.repliesPolicy",
                 selection: $repliesPolicy)
          {
            ForEach(Models.List.RepliesPolicy.allCases) { policy in
              Text(policy.title)
                .tag(policy)
            }
          }
          Toggle("list.edit.isExclusive", isOn: $isExclusive)
        }
        .listRowBackground(theme.primaryBackgroundColor)
      }
      .scrollContentBackground(.hidden)
      .background(theme.secondaryBackgroundColor)
      .toolbar {
        CancelToolbarItem()
        ToolbarItem {
          Button {
            Task {
              isSaving = true
              let _: Models.List = try await client.post(endpoint: Lists.createList(title: title,
                                                                                    repliesPolicy: repliesPolicy,
                                                                                    exclusive: isExclusive))
              await currentAccount.fetchLists()
              isSaving = false
              dismiss()
            }
          } label: {
            if isSaving {
              ProgressView()
            } else {
              Text("lists.create.confirm")
            }
          }
        }
      }
      .navigationTitle(title)
      .navigationBarTitleDisplayMode(.inline)
    }
  }
}
