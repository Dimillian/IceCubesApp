import DesignSystem
import Models
import NetworkClient
import SwiftUI

@MainActor
public struct EditRelationshipNoteView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(Theme.self) private var theme
  @Environment(MastodonClient.self) private var client

  let accountId: String
  let relationship: Relationship?
  let onSave: () -> Void
  
  @State private var note: String = ""
  @State private var isSaving: Bool = false
  @State private var saveError: Bool = false

  public var body: some View {
    NavigationStack {
      Form {
        Section("account.relation.note.label") {
          TextField(
            "account.relation.note.edit.placeholder", text: $note, axis: .vertical
          )
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
      .alert(
        "account.relation.note.edit.error.save.title",
        isPresented: $saveError,
        actions: {
          Button("alert.button.ok", action: {})
        }, message: { Text("account.relation.note.edit.error.save.message") }
      )
      .task {
        note = relationship?.note ?? ""
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
          await save()
          onSave()
          dismiss()
        }
      } label: {
        if isSaving {
          ProgressView()
        } else {
          Text("action.save").bold()
        }
      }
    }
  }
}

extension EditRelationshipNoteView {
  private func save() async {
    isSaving = true
    do {
      _ = try await client.post(
        endpoint: Accounts.relationshipNote(
          id: accountId, json: RelationshipNoteData(note: note)))
      isSaving = false
    } catch {
      isSaving = false
      saveError = true
    }
  }
}
