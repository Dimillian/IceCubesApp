import DesignSystem
import Env
import Models
import NetworkClient
import SwiftUI

@MainActor
public struct NotificationsRequestsListView: View {
  @Environment(MastodonClient.self) private var client
  @Environment(Theme.self) private var theme
  @Environment(RouterPath.self) private var routerPath

  enum ViewState {
    case loading
    case error
    case requests(_ data: [NotificationsRequest])
  }

  @State private var viewState: ViewState = .loading
  @State private var isProcessingRequests: Bool = false
  @State private var isInSelectMode: Bool = false
  @State private var selectedRequests: [NotificationsRequest] = []

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
        ErrorView(
          title: "notifications.error.title",
          message: "notifications.error.message",
          buttonTitle: "action.retry"
        ) {
          await fetchRequests(client)
        }
        #if !os(visionOS)
          .listRowBackground(theme.primaryBackgroundColor)
        #endif
        .listSectionSeparator(.hidden)
      case let .requests(data):
        if isInSelectMode {
          selectSection(data: data)
        }
        requestsSection(data: data)
      }
    }
    .listStyle(.plain)
    #if !os(visionOS)
      .scrollContentBackground(.hidden)
      .background(theme.primaryBackgroundColor)
    #endif
    .navigationTitle("notifications.content-filter.requests.title")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .navigationBarTrailing) {
        Button {
          withAnimation {
            isInSelectMode.toggle()
            if !isInSelectMode {
              selectedRequests.removeAll()
            }
          }
        } label: {
          Text(isInSelectMode ? "Cancel" : "Select")
        }
      }
    }
    .task {
      await fetchRequests(client)
    }
    .refreshable {
      await fetchRequests(client)
    }
  }

  private func selectSection(data: [NotificationsRequest]) -> some View {
    Section {
      HStack(alignment: .center) {
        Button {
          withAnimation {
            selectedRequests = data
          }
        } label: {
          Text("Select all")
        }
        .buttonStyle(.bordered)
        Button {
          Task {
            await acceptSelectedRequests(client)
            isInSelectMode = false
            selectedRequests.removeAll()
          }
        } label: {
          Text("Accept")
        }
        .disabled(isProcessingRequests)
        .buttonStyle(.borderedProminent)

        Button {
          Task {
            await rejectSelectedRequests(client)
            isInSelectMode = false
            selectedRequests.removeAll()
          }
        } label: {
          Text("Reject")
        }
        .disabled(isProcessingRequests)
        .buttonStyle(.bordered)
        .tint(.red)
      }
    }
    .listRowBackground(theme.primaryBackgroundColor)
  }

  private func requestsSection(data: [NotificationsRequest]) -> some View {
    Section {
      ForEach(data) { request in
        let isSelected = selectedRequests.contains(where: { $0.id == request.id })
        HStack {
          if isInSelectMode {
            if isSelected {
              Image(systemName: "checkmark.circle.fill")
                .resizable()
                .frame(width: 20, height: 20)
                .foregroundStyle(theme.tintColor)
            } else {
              Circle()
                .strokeBorder(theme.tintColor, lineWidth: 1)
                .frame(width: 20, height: 20)
            }
          }
          NotificationsRequestsRowView(request: request)
        }
        .onTapGesture {
          if isInSelectMode {
            withAnimation {
              if isSelected {
                selectedRequests.removeAll { $0.id == request.id }
              } else {
                selectedRequests.append(request)
              }
            }
          } else {
            routerPath.navigate(to: .notificationForAccount(accountId: request.account.id))
          }
        }
        .listRowInsets(
          .init(
            top: 12,
            leading: .layoutPadding,
            bottom: 12,
            trailing: .layoutPadding)
        )
        #if os(visionOS)
          .listRowBackground(
            RoundedRectangle(cornerRadius: 8)
              .foregroundStyle(.background))
        #else
          .listRowBackground(theme.primaryBackgroundColor)
        #endif
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

  private func fetchRequests(_ client: MastodonClient) async {
    do {
      viewState = try .requests(await client.get(endpoint: Notifications.requests))
    } catch {
      viewState = .error
    }
  }

  private func acceptRequest(_ client: MastodonClient, _ request: NotificationsRequest) async {
    _ = try? await client.post(endpoint: Notifications.acceptRequests(ids: [request.id]))
    await fetchRequests(client)
  }

  private func dismissRequest(_ client: MastodonClient, _ request: NotificationsRequest) async {
    _ = try? await client.post(endpoint: Notifications.dismissRequests(ids: [request.id]))
    await fetchRequests(client)
  }

  private func acceptSelectedRequests(_ client: MastodonClient) async {
    isProcessingRequests = true
    _ = try? await client.post(
      endpoint: Notifications.acceptRequests(ids: selectedRequests.map { $0.id }))
    await fetchRequests(client)
    isProcessingRequests = false
  }

  private func rejectSelectedRequests(_ client: MastodonClient) async {
    isProcessingRequests = true
    _ = try? await client.post(
      endpoint: Notifications.dismissRequests(ids: selectedRequests.map { $0.id }))
    await fetchRequests(client)
    isProcessingRequests = false
  }
}
