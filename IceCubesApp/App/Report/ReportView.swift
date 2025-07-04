import DesignSystem
import Env
import Models
import NetworkClient
import StatusKit
import SwiftUI

public struct ReportView: View {
  @Environment(\.dismiss) private var dismiss

  @Environment(Theme.self) private var theme
  @Environment(MastodonClient.self) private var client

  let status: Status
  @State private var commentText: String = ""
  @State private var isSendingReport: Bool = false

  struct ReportSent: Decodable {
    let id: String
  }

  public var body: some View {
    NavigationStack {
      Form {
        Section {
          TextField(
            "report.comment.placeholder",
            text: $commentText,
            axis: .vertical)
        }
        .listRowBackground(theme.primaryBackgroundColor)

        StatusEmbeddedView(status: status, client: .init(server: ""), routerPath: RouterPath())
          .allowsHitTesting(false)
          .listRowBackground(theme.primaryBackgroundColor)
      }
      .navigationTitle("report.title")
      .navigationBarTitleDisplayMode(.inline)
      #if !os(visionOS)
        .scrollContentBackground(.hidden)
        .background(theme.secondaryBackgroundColor)
        .scrollDismissesKeyboard(.immediately)
      #endif
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button {
            isSendingReport = true
            Task {
              do {
                let _: ReportSent =
                  try await client.post(
                    endpoint: Statuses.report(
                      accountId: status.account.id,
                      statusId: status.id,
                      comment: commentText))
                dismiss()
                isSendingReport = false
              } catch {
                isSendingReport = false
              }
            }
          } label: {
            if isSendingReport {
              ProgressView()
            } else {
              Text("report.action.send")
            }
          }
        }

        CancelToolbarItem()
      }
    }
  }
}
