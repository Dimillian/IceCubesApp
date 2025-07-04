import DesignSystem
import Models
import SwiftData
import SwiftUI

extension StatusEditor {
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
                  .lineLimit(10)
                  .foregroundStyle(theme.labelColor)
                Text(draft.creationDate, style: .relative)
                  .font(.footnote)
                  .foregroundStyle(.gray)
              }
            }
            #if os(visionOS)
              .foregroundStyle(theme.labelColor)
            #else
              .listRowBackground(theme.primaryBackgroundColor.opacity(0.4))
            #endif
          }
          .onDelete { indexes in
            if let index = indexes.first {
              context.delete(drafts[index])
            }
          }
        }
        .toolbar {
          CancelToolbarItem()
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(.clear)
        .navigationTitle("status.editor.drafts.navigation-title")
        .navigationBarTitleDisplayMode(.inline)
        .presentationDetents([.medium, .large])
      }
    }
  }
}
