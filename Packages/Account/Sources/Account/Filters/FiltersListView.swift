import DesignSystem
import Env
import Models
import Network
import SwiftUI

@MainActor
public struct FiltersListView: View {
  @Environment(\.dismiss) private var dismiss

  @Environment(Theme.self) private var theme
  @Environment(CurrentAccount.self) private var account
  @Environment(Client.self) private var client

  @State private var isLoading: Bool = true
  @State private var filters: [ServerFilter] = []

  public init() {}

  public var body: some View {
    NavigationStack {
      Form {
        if !isLoading, filters.isEmpty {
          EmptyView()
        } else {
          Section {
            if isLoading, filters.isEmpty {
              ProgressView()
            } else {
              ForEach(filters) { filter in
                NavigationLink(destination: EditFilterView(filter: filter)) {
                  VStack(alignment: .leading) {
                    Text(filter.title)
                      .font(.scaledSubheadline)
                    Text("\(filter.context.map(\.name).joined(separator: ", "))")
                      .font(.scaledBody)
                      .foregroundStyle(.secondary)
                    if filter.hasExpiry() {
                      if filter.isExpired() {
                        Text("filter.expired")
                          .font(.footnote)
                          .foregroundStyle(.secondary)
                      } else {
                        Text("filter.expiry-\(filter.expiresAt!.relativeFormatted)")
                          .font(.footnote)
                          .foregroundStyle(.secondary)
                      }
                    }
                  }
                }
              }
              .onDelete { indexes in
                deleteFilter(indexes: indexes)
              }
            }
          }
          #if !os(visionOS)
          .listRowBackground(theme.primaryBackgroundColor)
          #endif
        }

        Section {
          NavigationLink(destination: EditFilterView(filter: nil)) {
            Label("filter.new", systemImage: "plus")
          }
        }
        #if !os(visionOS)
        .listRowBackground(theme.primaryBackgroundColor)
        #endif
      }
      .toolbar {
        toolbarContent
      }
      .navigationTitle("filter.filters")
      .navigationBarTitleDisplayMode(.inline)
      #if !os(visionOS)
        .scrollContentBackground(.hidden)
        .background(theme.secondaryBackgroundColor)
      #endif
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
      Button {
        dismiss()
      } label: {
        Text("action.done").bold()
      }
    }
  }
}
