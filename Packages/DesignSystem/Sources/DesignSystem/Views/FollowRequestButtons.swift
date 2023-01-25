//
//  FollowRequestButtons.swift
//  
//
//  Created by Jérôme Danthinne on 25/01/2023.
//

import Models
import Env
import SwiftUI

public struct FollowRequestButtons: View {
  @EnvironmentObject private var currentAccount: CurrentAccount

  let account: Account
  let requestUpdated: (() -> Void)?

  public init(account: Account, requestUpdated: (() -> Void)? = nil) {
    self.account = account
    self.requestUpdated = requestUpdated
  }

  public var body: some View {
    HStack {
      Button {
        Task {
          await currentAccount.acceptFollowerRequest(id: account.id)
          requestUpdated?()
        }
      } label: {
        Text("account.follow-request.accept")
          .frame(maxWidth: .infinity)
      }
      Button {
        Task {
          await currentAccount.rejectFollowerRequest(id: account.id)
          requestUpdated?()
        }
      } label: {
        Text("account.follow-request.reject")
          .frame(maxWidth: .infinity)
      }
    }
    .buttonStyle(.bordered)
    .disabled(currentAccount.isUpdating)
    .padding(.top, 4)
  }
}
