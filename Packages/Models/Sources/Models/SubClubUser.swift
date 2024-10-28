import Foundation

public struct SubClubUser: Sendable, Identifiable, Decodable {
  public struct Subscription: Sendable, Decodable {
    public let paymentType: String
    public let currency: String
    public let interval: String
    public let intervalCount: Int
    public let unitAmount: Int

    public var formattedAmount: String {
      let formatter = NumberFormatter()
      formatter.numberStyle = .currency
      formatter.locale = Locale(identifier: "en_US")
      formatter.maximumFractionDigits = 0
      return formatter.string(from: .init(integerLiteral: unitAmount / 100)) ?? "$NaN"
    }
  }

  public let id: String
  public let subscription: Subscription?
}
