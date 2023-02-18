import DesignSystem
import Network
import SwiftUI

public struct EditRelationshipNoteView: View {
  @Environment(\.dismiss) private var dismiss
  @EnvironmentObject private var theme: Theme
  @EnvironmentObject private var client: Client
  
  // need this model to refresh after storing the new note on mastodon
  var accountDetailViewModel: AccountDetailViewModel
  
  @StateObject private var viewModel = EditRelationshipNoteViewModel()
  
  public var body: some View {
    NavigationStack {
      Form {
        Section("account.relation.note.label") {
          TextField("account.relation.note.edit.placeholder", text: $viewModel.note, axis: .vertical)
            .frame(minHeight: 150, maxHeight: 150, alignment: .top)
        }
        .listRowBackground(theme.primaryBackgroundColor)
      }
      .scrollContentBackground(.hidden)
      .background(theme.secondaryBackgroundColor)
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
          Text("action.save")
        }
      }
    }
  }
}
