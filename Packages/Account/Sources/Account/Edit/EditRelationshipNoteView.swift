import DesignSystem
import Network
import SwiftUI

@MainActor
public struct EditRelationshipNoteView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(Theme.self) private var theme
  @Environment(Client.self) private var client

  @State var accountDetailViewModel: AccountDetailViewModel
  @State private var viewModel = EditRelationshipNoteViewModel()

  public var body: some View {
    NavigationStack {
      Form {
        Section("account.relation.note.label") {
          TextField("account.relation.note.edit.placeholder", text: $viewModel.note, axis: .vertical)
            .frame(minHeight: 150, maxHeight: 150, alignment: .top)
        }
        #if !os(visionOS)
        .listRowBackground(theme.primaryBackgroundColor)
        #endif
      }
      #if !os(visionOS)
      .scrollContentBackground(.hidden)
      .background(theme.secondaryBackgroundColor)
      #endif
      .navigationTitle("account.relation.note.edit")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        toolbarContent
      }
      .alert("account.relation.note.edit.error.save.title",
             isPresented: $viewModel.saveError,
             actions: {
               Button("alert.button.ok", action: {})
             }, message: { Text("account.relation.note.edit.error.save.message") })
      .task {
        viewModel.client = client
        viewModel.relatedAccountId = accountDetailViewModel.accountId
        viewModel.note = accountDetailViewModel.relationship?.note ?? ""
      }
    }
  }

  @ToolbarContentBuilder
  private var toolbarContent: some ToolbarContent {
    ToolbarItem(placement: .navigationBarLeading) {
      Button("action.cancel") {
        dismiss()
      }
    }

    ToolbarItem(placement: .navigationBarTrailing) {
      Button {
        Task {
          await viewModel.save()
          await accountDetailViewModel.fetchAccount()
          dismiss()
        }
      } label: {
        if viewModel.isSaving {
          ProgressView()
        } else {
          Text("action.save").bold()
        }
      }
    }
  }
}
