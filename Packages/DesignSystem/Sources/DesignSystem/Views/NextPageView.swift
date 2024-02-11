import SwiftUI

public struct NextPageView: View {
  @State private var isLoadingNextPage: Bool = false
  @State private var showRetry: Bool = false

  let loadNextPage: (() async throws -> Void)
  
  public init(loadNextPage: @escaping (() async throws -> Void)) {
    self.loadNextPage = loadNextPage
  }
  
  public var body: some View {
    HStack {
      Spacer()
      if showRetry {
        Button {
          Task {
            showRetry = false
            await executeTask()
          }
        } label: {
          Label("action.retry", systemImage: "arrow.clockwise")
        }
        .buttonStyle(.bordered)
      } else {
        Label("placeholder.loading.short", systemImage: "arrow.down")
          .font(.footnote)
          .foregroundStyle(.secondary)
          .symbolEffect(.pulse, value: isLoadingNextPage)
      }
      Spacer()
    }
    .task {
      await executeTask()
    }
    .listRowSeparator(.hidden, edges: .all)
  }
  
  private func executeTask() async {
    showRetry = false
    defer {
      isLoadingNextPage = false
    }
    guard !isLoadingNextPage else { return }
    isLoadingNextPage = true
    do {
      try await loadNextPage()
    } catch {
      showRetry = true
    }
  }
}
