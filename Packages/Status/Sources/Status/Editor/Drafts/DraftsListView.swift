import DesignSystem
import Models
import SwiftData
import SwiftUI

struct DraftsListView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.modelContext) private var context

  @Environment(Theme.self) private var theme

  @Query(sort: \Draft.creationDate, order: .reverse) var drafts: [Draft]

  @Binding var selectedDraft: Draft?

  var body: some View {
    NavigationStack {
      List {
        ForEach(drafts) { draft in
          Button {
            selectedDraft = draft
            dismiss()
          } label: {
            VStack(alignment: .leading, spacing: 8) {
              Text(draft.content)
                .font(.body)
                .lineLimit(3)
                .foregroundStyle(theme.labelColor)
              Text(draft.creationDate, style: .relative)
                .font(.footnote)
                .foregroundStyle(.gray)
            }
          }.listRowBackground(theme.primaryBackgroundColor)
        }
        .onDelete { indexes in
          if let index = indexes.first {
            context.delete(drafts[index])
          }
        }
      }
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          Button("action.cancel", action: { dismiss() })
        }
      }
      .scrollContentBackground(.hidden)
      .background(theme.secondaryBackgroundColor)
      .navigationTitle("status.editor.drafts.navigation-title")
      .navigationBarTitleDisplayMode(.inline)
    }
  }
}
