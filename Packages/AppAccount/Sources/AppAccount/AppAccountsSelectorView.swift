//
//  File.swift
//  
//
//  Created by Dennis Plöger on 05.01.24.
//

import Foundation
import SwiftUI
import Env
import DesignSystem

@MainActor
public struct AppAccountsSelectorView: View {
    @Environment(Theme.self) private var theme
    
    var routerPath: RouterPath
    
    @Binding var accountsViewModel: [AppAccountViewModel]
    @Binding var isPresented: Bool

    private let accountCreationEnabled: Bool
    
    public init(routerPath: RouterPath,
                accountCreationEnabled: Bool = true,
                accountsViewModel: Binding<[AppAccountViewModel]>,
                isPresented: Binding<Bool>)
    {
      self.routerPath = routerPath
      self.accountCreationEnabled = accountCreationEnabled
      self._accountsViewModel = accountsViewModel
      self._isPresented = isPresented
    }
    
    public var body: some View {
        NavigationStack {
            List {
              Section {
                ForEach(accountsViewModel.sorted { $0.acct < $1.acct }, id: \.appAccount.id) { viewModel in
                  AppAccountView(viewModel: viewModel)
                }
                addAccountButton
              }
              #if !os(visionOS)
                .listRowBackground(theme.primaryBackgroundColor)
              #endif

              if accountCreationEnabled {
                Section {
                  settingsButton
                  aboutButton
                  supportButton
                }
                #if !os(visionOS)
                  .listRowBackground(theme.primaryBackgroundColor)
                #endif
              }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(.clear)
            .navigationTitle("settings.section.accounts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
              ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                  isPresented.toggle()
                } label: {
                  Text("action.done").bold()
                }
              }
            }
            .environment(routerPath)
        }
    }
    
    private var addAccountButton: some View {
      Button {
        HapticManager.shared.fireHaptic(.buttonPress)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
          routerPath.presentedSheet = .addAccount
        }
      } label: {
        Label("app-account.button.add", systemImage: "person.badge.plus")
      }
    }
    
    private var settingsButton: some View {
      Button {
        isPresented = false
        HapticManager.shared.fireHaptic(.buttonPress)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
          routerPath.presentedSheet = .settings
        }
      } label: {
        Label("tab.settings", systemImage: "gear")
      }
    }
    
    private var supportButton: some View {
      Button {
        isPresented = false
        HapticManager.shared.fireHaptic(.buttonPress)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
          routerPath.presentedSheet = .support
        }
      } label: {
        Label("settings.app.support", systemImage: "wand.and.stars")
      }
    }
    
    private var aboutButton: some View {
      Button {
        isPresented = false
        HapticManager.shared.fireHaptic(.buttonPress)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
          routerPath.presentedSheet = .about
        }
      } label: {
        Label("account.edit.about", systemImage: "info.circle")
      }
    }

}
