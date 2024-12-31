import DesignSystem
import Env
import SwiftUI

struct StatusRowPremiumView: View {
  @Environment(\.isHomeTimeline) private var isHomeTimeline

  let viewModel: StatusRowViewModel

  var body: some View {
    if isHomeTimeline, viewModel.status.account.isPremiumAccount {
      Text("From a subscribed premium account")
        .font(.scaledFootnote)
        .foregroundStyle(.secondary)
        .fontWeight(.semibold)
    }
  }
}
