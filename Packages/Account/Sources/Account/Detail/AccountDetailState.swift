import Foundation
import Models

enum AccountDetailState {
  case loading
  case display(
    account: Account,
    featuredTags: [FeaturedTag],
    relationships: [Relationship],
    fields: [Account.Field])
  case error(error: Error)
}
