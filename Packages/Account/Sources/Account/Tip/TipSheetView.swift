import SwiftUI
import Models
import Env
import DesignSystem
import WrappingHStack

struct TipSheetView: View {
  private let tips = ["$2.00", "$5.00", "$10.00", "$15.00", "$15.00", "$20.00", "$50.00"]
  @Environment(\.dismiss) private var dismiss
  @Environment(Theme.self) private var theme: Theme
  
  @State private var selectedTip: String?
  
  let account: Account
  
  var body: some View {
    VStack {
      HStack {
        Spacer()
        Button {
          dismiss()
        } label: {
          Image(systemName: "xmark.circle")
            .font(.title3)
        }
        .padding(.trailing, 12)
        .padding(.top, 8)
      }
      VStack(alignment: .leading, spacing: 8) {
        Text("Send a tip")
          .font(.title2)
        Text("Send a tip to @\(account.username) to get access to exclusive content!")
        WrappingHStack(tips, id: \.self, spacing: .constant(12)) { tip in
          Button {
            withAnimation {
              selectedTip = tip
            }
          } label: {
            Text(tip)
          }
          .buttonStyle(.bordered)
          .padding(.vertical, 8)
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(12)
      .background(theme.secondaryBackgroundColor.opacity(0.4))
      .cornerRadius(8)
      .padding(12)
      
      Spacer()
      
      if let selectedTip {
        HStack(alignment: .top) {
          Text("Send \(selectedTip)")
            .font(.headline)
            .fontWeight(.bold)
        }
        .transition(.push(from: .bottom))
        .frame(height: 50)
        .frame(maxWidth: .infinity)
        .background(theme.tintColor.opacity(0.6))
        .onTapGesture {
          dismiss()
        }
        .ignoresSafeArea()
      }
    }
    .presentationBackground(.thinMaterial)
    .presentationCornerRadius(8)
    .presentationDetents([.height(330)])
  }
}
