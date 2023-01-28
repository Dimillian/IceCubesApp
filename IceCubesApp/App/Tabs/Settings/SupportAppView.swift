import DesignSystem
import Env
import RevenueCat
import Shimmer
import SwiftUI

struct SupportAppView: View {
  enum Tips: String, CaseIterable {
    case one, two, three, four

    init(productId: String) {
      self = .init(rawValue: String(productId.split(separator: ".")[2]))!
    }

    var productId: String {
      "icecubes.tipjar.\(rawValue)"
    }

    var title: LocalizedStringKey {
      switch self {
      case .one:
        return "settings.support.one.title"
      case .two:
        return "settings.support.two.title"
      case .three:
        return "settings.support.three.title"
      case .four:
        return "settings.support.four.title"
      }
    }

    var subtitle: LocalizedStringKey {
      switch self {
      case .one:
        return "settings.support.one.subtitle"
      case .two:
        return "settings.support.two.subtitle"
      case .three:
        return "settings.support.three.subtitle"
      case .four:
        return "settings.support.four.subtitle"
      }
    }
  }

  @EnvironmentObject private var theme: Theme

  @State private var loadingProducts: Bool = false
  @State private var products: [StoreProduct] = []
  @State private var isProcessingPurchase: Bool = false
  @State private var purchaseSuccessDisplayed: Bool = false
  @State private var purchaseErrorDisplayed: Bool = false

  var body: some View {
    Form {
      Section {
        HStack(alignment: .top, spacing: 12) {
          VStack(spacing: 18) {
            Image("avatar")
              .resizable()
              .frame(width: 50, height: 50)
              .cornerRadius(4)
            Image("icon0")
              .resizable()
              .frame(width: 50, height: 50)
              .cornerRadius(4)
          }
          Text("settings.support.message-from-dev")
        }
      }
      .listRowBackground(theme.primaryBackgroundColor)

      Section {
        if loadingProducts {
          HStack {
            VStack(alignment: .leading) {
              Text("placeholder.loading.short.")
                .font(.scaledSubheadline)
              Text("settings.support.placeholder.loading-subtitle")
                .font(.scaledFootnote)
                .foregroundColor(.gray)
            }
            .padding(.vertical, 8)
          }
          .redacted(reason: .placeholder)
          .shimmering()
        } else {
          ForEach(products, id: \.productIdentifier) { product in
            let tip = Tips(productId: product.productIdentifier)
            HStack {
              VStack(alignment: .leading) {
                Text(tip.title)
                  .font(.scaledSubheadline)
                Text(tip.subtitle)
                  .font(.scaledFootnote)
                  .foregroundColor(.gray)
              }
              Spacer()
              Button {
                if !isProcessingPurchase {
                  isProcessingPurchase = true
                  Task {
                    do {
                      let result = try await Purchases.shared.purchase(product: product)
                      if !result.userCancelled {
                        purchaseSuccessDisplayed = true
                      }
                    } catch {
                      purchaseErrorDisplayed = true
                    }
                    isProcessingPurchase = false
                  }
                }
              } label: {
                if isProcessingPurchase {
                  ProgressView()
                } else {
                  Text(product.localizedPriceString)
                }
              }
              .buttonStyle(.bordered)
            }
            .padding(.vertical, 8)
          }
        }
      }
      .listRowBackground(theme.primaryBackgroundColor)
    }
    .navigationTitle("settings.support.navigation-title")
    .scrollContentBackground(.hidden)
    .background(theme.secondaryBackgroundColor)
    .alert("settings.support.alert.title", isPresented: $purchaseSuccessDisplayed, actions: {
      Button { purchaseSuccessDisplayed = false } label: { Text("alert.button.ok") }
    }, message: {
      Text("settings.support.alert.message")
    })
    .alert("alert.error", isPresented: $purchaseErrorDisplayed, actions: {
      Button { purchaseErrorDisplayed = false } label: { Text("alert.button.ok") }
    }, message: {
      Text("settings.support.alert.error.message")
    })
    .onAppear {
      loadingProducts = true
      Purchases.shared.getProducts(Tips.allCases.map { $0.productId }) { products in
        self.products = products.sorted(by: { $0.price < $1.price })
        withAnimation {
          loadingProducts = false
        }
      }
    }
  }
}
