import SwiftUI
import Timeline
import Env
import Network
import Combine
import DesignSystem
import Models

struct TimelineTab: View {
  @EnvironmentObject private var appAccounts: AppAccountsManager
  @EnvironmentObject private var theme: Theme
  @EnvironmentObject private var currentAccount: CurrentAccount
  @EnvironmentObject private var client: Client
  @StateObject private var routeurPath = RouterPath()
  @Binding var popToRootTab: Tab
  
  @State private var timeline: TimelineFilter = .home
  @State private var scrollToTopSignal: Int = 0
  @State private var isAddAccountSheetDisplayed = false
  @State private var accountsViewModel: [AppAccountViewModel] = []
  
  var body: some View {
    NavigationStack(path: $routeurPath.path) {
      TimelineView(timeline: $timeline, scrollToTopSignal: $scrollToTopSignal)
        .withAppRouteur()
        .withSheetDestinations(sheetDestinations: $routeurPath.presentedSheet)
        .toolbar {
          ToolbarTitleMenu {
            timelineFilterButton
          }
          if client.isAuth {
            ToolbarItem(placement: .navigationBarLeading) {
              accountButton
            }
            statusEditorToolbarItem(routeurPath: routeurPath)
          } else {
            ToolbarItem(placement: .navigationBarTrailing) {
              addAccountButton
            }
          }
        }
        .id(currentAccount.account?.id)
    }
    .sheet(isPresented: $isAddAccountSheetDisplayed) {
      AddAccountView()
    }
    .onAppear {
      routeurPath.client = client
      timeline = client.isAuth ? .home : .pub
      Task {
        await currentAccount.fetchLists()
      }
    }
    .environmentObject(routeurPath)
    .onChange(of: $popToRootTab.wrappedValue) { popToRootTab in
      if popToRootTab == .timeline {
        if routeurPath.path.isEmpty {
          scrollToTopSignal += 1
        } else {
          routeurPath.path = []
        }
      }
    }
    .onChange(of: currentAccount.account?.id) { _ in
      routeurPath.path = []
    }
  }
  
  
  @ViewBuilder
  private var timelineFilterButton: some View {
    ForEach(TimelineFilter.availableTimeline(client: client), id: \.self) { timeline in
      Button {
        self.timeline = timeline
      } label: {
        Label(timeline.title(), systemImage: timeline.iconName() ?? "")
      }
    }
    if !currentAccount.lists.isEmpty {
      Menu("Lists") {
        ForEach(currentAccount.lists) { list in
          Button {
            timeline = .list(list: list)
          } label: {
            Label(list.title, systemImage: "list.bullet")
          }
        }
      }
    }
  }
  
  private var accountButton: some View {
    Button {
      if let account = currentAccount.account {
        routeurPath.navigate(to: .accountDetailWithAccount(account: account))
      }
    } label: {
      if let avatar = currentAccount.account?.avatar {
        AvatarView(url: avatar, size: .badge)
      }
    }
    .onAppear {
      if accountsViewModel.isEmpty || appAccounts.availableAccounts.count != accountsViewModel.count {
        accountsViewModel = []
        for account in appAccounts.availableAccounts {
          let viewModel: AppAccountViewModel = .init(appAccount: account)
          accountsViewModel.append(viewModel)
          Task {
            await viewModel.fetchAccount()
          }
        }
      }
    }
    .contextMenu {
      ForEach(accountsViewModel, id: \.appAccount.id) { viewModel in
        Button {
          appAccounts.currentAccount = viewModel.appAccount
          timeline = .home
        } label: {
          HStack {
            if viewModel.account?.id == currentAccount.account?.id {
              Image(systemName: "checkmark.circle.fill")
            }
            Text("\(viewModel.account?.displayName ?? "")")
          }
        }
      }
      Button {
        isAddAccountSheetDisplayed = true
      } label: {
        Label("Add Account", systemImage: "person.badge.plus")
      }
    }

  }
  
  private var addAccountButton: some View {
    Button {
      isAddAccountSheetDisplayed = true
    } label: {
      Image(systemName: "person.badge.plus")
    }
  }
}
