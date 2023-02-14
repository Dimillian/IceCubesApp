import SwiftUI
import Models
import Env
import DesignSystem
import Status
import Network

public struct ReportView: View {
  @Environment(\.dismiss) private var dismiss
  
  @EnvironmentObject private var theme: Theme
  @EnvironmentObject private var client: Client
  
  let status: Status
  @State private var commentText: String = ""
  @State private var isSendingReport: Bool = false
  
  struct ReportSent: Decodable {
    let id : String
  }
  
  public var body: some View {
    NavigationStack {
      Form {
        Section {
          TextField("report.comment.placeholder",
                    text: $commentText,
                    axis: .vertical)
        }
        .listRowBackground(theme.primaryBackgroundColor)
        
        StatusEmbeddedView(status: status)
          .allowsHitTesting(false)
          .listRowBackground(theme.primaryBackgroundColor)
      }
      .navigationTitle("report.title")
      .navigationBarTitleDisplayMode(.inline)
      .scrollContentBackground(.hidden)
      .background(theme.secondaryBackgroundColor)
      .scrollDismissesKeyboard(.immediately)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button {
            isSendingReport = true
            Task {
              do {
                let _: ReportSent =
                try await client.post(endpoint: Statuses.report(accountId: status.account.id,
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
        
        ToolbarItem(placement: .navigationBarLeading) {
          Button {
            dismiss()
          } label: {
            Text("action.cancel")
          }
        }
      }
    }
  }
}
