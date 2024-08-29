import DesignSystem
import Models
import Network
import SwiftUI

@MainActor
public struct NotificationsRequestsListView: View {
  @Environment(Client.self) private var client
  @Environment(Theme.self) private var theme

  enum ViewState {
    case loading
    case error
    case requests(_ data: [NotificationsRequest])
  }

  @State private var viewState: ViewState = .loading

  public init() {}

  public var body: some View {
    List {
      switch viewState {
      case .loading:
        ProgressView()
        #if !os(visionOS)
          .listRowBackground(theme.primaryBackgroundColor)
        #endif
          .listSectionSeparator(.hidden)
      case .error:
        ErrorView(title: "notifications.error.title",
                  message: "notifications.error.message",
                  buttonTitle: "action.retry")
        {
          await fetchRequests()
        }
        #if !os(visionOS)
        .listRowBackground(theme.primaryBackgroundColor)
        #endif
        .listSectionSeparator(.hidden)
      case let .requests(data):
        ForEach(data) { request in
          NotificationsRequestsRowView(request: request)
            .swipeActions {
              Button {
                Task { await acceptRequest(request) }
              } label: {
                Label("account.follow-request.accept", systemImage: "checkmark")
              }

              Button {
                Task { await dismissRequest(request) }
              } label: {
                Label("account.follow-request.reject", systemImage: "xmark")
              }
              .tint(.red)
            }
        }
      }
    }
    .listStyle(.plain)
    #if !os(visionOS)
      .scrollContentBackground(.hidden)
      .background(theme.primaryBackgroundColor)
    #endif
      .navigationTitle("notifications.content-filter.requests.title")
      .navigationBarTitleDisplayMode(.inline)
      .task {
        await fetchRequests()
      }
      .refreshable {
        await fetchRequests()
      }
  }

  private func fetchRequests() async {
    do {
      viewState = try .requests(await client.get(endpoint: Notifications.requests))
    } catch {
      viewState = .error
    }
  }

  private func acceptRequest(_ request: NotificationsRequest) async {
    _ = try? await client.post(endpoint: Notifications.acceptRequest(id: request.id))
    await fetchRequests()
  }

  private func dismissRequest(_ request: NotificationsRequest) async {
    _ = try? await client.post(endpoint: Notifications.dismissRequest(id: request.id))
    await fetchRequests()
  }
}
