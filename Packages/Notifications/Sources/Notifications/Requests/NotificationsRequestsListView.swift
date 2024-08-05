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
          await fetchRequests(client)
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
                Task { await acceptRequest(client, request) }
              } label: {
                Label("account.follow-request.accept", systemImage: "checkmark")
              }

              Button {
                Task { await dismissRequest(client, request) }
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
        await fetchRequests(client)
      }
      .refreshable {
        await fetchRequests(client)
      }
  }

  private func fetchRequests(_ client: Client) async {
    do {
      viewState = try .requests(await client.get(endpoint: Notifications.requests))
    } catch {
      viewState = .error
    }
  }

  private func acceptRequest(_ client: Client, _ request: NotificationsRequest) async {
    _ = try? await client.post(endpoint: Notifications.acceptRequest(id: request.id))
    await fetchRequests(client)
  }

  private func dismissRequest(_ client: Client, _ request: NotificationsRequest) async {
    _ = try? await client.post(endpoint: Notifications.dismissRequest(id: request.id))
    await fetchRequests(client)
  }
}
