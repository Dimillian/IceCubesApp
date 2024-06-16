import DesignSystem
import Env
import SwiftUI

struct StatusRowPremiumView: View {
  let viewModel: StatusRowViewModel

  var body: some View {
    if viewModel.status.account.isPremiumAccount {
      Text("From a subscribed premium account")
        .font(.scaledFootnote)
        .foregroundStyle(.secondary)
        .fontWeight(.semibold)
    }
  }
}
