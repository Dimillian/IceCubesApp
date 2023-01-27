import DesignSystem
import Env
import Models
import Network
import SwiftUI

public struct FiltersListView: View {
  @Environment(\.dismiss) private var dismiss

  @EnvironmentObject private var theme: Theme
  @EnvironmentObject private var account: CurrentAccount
  @EnvironmentObject private var client: Client

  @State private var isLoading: Bool = true
  @State private var filters: [ServerFilter] = []

  public init() {}

  public var body: some View {
    NavigationStack {
      Form {
        if !isLoading && filters.isEmpty {
          EmptyView()
        } else {
          Section {
            if isLoading && filters.isEmpty {
              ProgressView()
            } else {
              ForEach(filters) { filter in
                NavigationLink(destination: EditFilterView(filter: filter)) {
                  VStack(alignment: .leading) {
                    Text(filter.title)
                      .font(.scaledSubheadline)
                    Text("\(filter.context.map { $0.name }.joined(separator: ", "))")
                      .font(.scaledBody)
                      .foregroundColor(.gray)
                  }
                }
              }
              .onDelete { indexes in
                deleteFilter(indexes: indexes)
              }
            }
          }
          .listRowBackground(theme.primaryBackgroundColor)
        }

        Section {
          NavigationLink(destination: EditFilterView(filter: nil)) {
            Label("filter.new", systemImage: "plus")
          }
        }
        .listRowBackground(theme.primaryBackgroundColor)
      }
      .toolbar {
        toolbarContent
      }
      .navigationTitle("filter.filters")
      .navigationBarTitleDisplayMode(.inline)
      .scrollContentBackground(.hidden)
      .background(theme.secondaryBackgroundColor)
      .task {
        do {
          isLoading = true
          filters = try await client.get(endpoint: ServerFilters.filters, forceVersion: .v2)
          isLoading = false
        } catch {
          isLoading = false
        }
      }
    }
  }

  private func deleteFilter(indexes: IndexSet) {
    if let index = indexes.first {
      Task {
        do {
          let response = try await client.delete(endpoint: ServerFilters.filter(id: filters[index].id),
                                                 forceVersion: .v2)
          if response?.statusCode == 200 {
            filters.remove(at: index)
          }
        } catch {}
      }
    }
  }

  @ToolbarContentBuilder
  private var toolbarContent: some ToolbarContent {
    ToolbarItem(placement: .navigationBarTrailing) {
      Button("action.done") {
        dismiss()
      }
    }
  }
}
