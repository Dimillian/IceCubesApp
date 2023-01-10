import SwiftUI
import Env
import DesignSystem
import RevenueCat
import Shimmer

struct SupportAppView: View {
  enum Tips: String, CaseIterable {
    case one, two, three
    
    init(productId: String) {
      self = .init(rawValue: String(productId.split(separator: ".")[2]))!
    }
    
    var productId: String {
      "icecubes.tipjar.\(rawValue)"
    }
    
    var title: String {
      switch self {
      case .one:
        return "🍬 Small Tip"
      case .two:
        return "☕️ Nice Tip"
      case .three:
        return "🤯 Generous Tip"
      }
    }
    
    var subtitle: String {
      switch self {
      case .one:
        return "Small, but cute, and it taste good!"
      case .two:
        return "I love the taste of a fancy coffee ❤️"
      case .three:
        return "You're insane, thank you so much!"
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
          Text("Hi there! My name is Thomas and I absolutely love creating open source apps. Ice Cubes is definitely one of my proudest projects to date - and let's be real, it's also the one that requires the most maintenance due to the ever-changing world of Mastodon and social media. If you're having a blast using Ice Cubes, consider tossing a little tip my way. It'll make my day (and help keep the app running smoothly for you). 🚀")
        }
      }
      .listRowBackground(theme.primaryBackgroundColor)
      
      Section {
        if loadingProducts {
          HStack {
            VStack(alignment: .leading) {
              Text("Loading ...")
                .font(.subheadline)
              Text("Loading subtitle...")
                .font(.footnote)
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
                  .font(.subheadline)
                Text(tip.subtitle)
                  .font(.footnote)
                  .foregroundColor(.gray)
              }
              Spacer()
              Button {
                isProcessingPurchase = true
                Task {
                  do {
                    _ = try await Purchases.shared.purchase(product: product)
                    purchaseSuccessDisplayed = true
                  } catch {
                    purchaseErrorDisplayed = true
                  }
                  isProcessingPurchase = false
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
    .navigationTitle("Support Ice Cubes")
    .scrollContentBackground(.hidden)
    .background(theme.secondaryBackgroundColor)
    .alert("Thanks!", isPresented: $purchaseSuccessDisplayed, actions: {
      Button { purchaseSuccessDisplayed = false } label: { Text("Ok") }
    }, message: {
      Text("Thanks you so much for your tip! It's greatly appreciated!")
    })
    .alert("Error!", isPresented: $purchaseErrorDisplayed, actions: {
      Button { purchaseErrorDisplayed = false } label: { Text("Ok") }
    }, message: {
      Text("Error processing your in app purchase, please try again.")
    })
    .onAppear {
      loadingProducts = true
      Purchases.shared.getProducts(Tips.allCases.map{ $0.productId }) { products in
        self.products = products.sorted(by: { $0.price < $1.price })
        withAnimation {
          loadingProducts = false
        }
      }
    }
  }
}
