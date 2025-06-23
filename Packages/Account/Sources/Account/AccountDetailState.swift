import Foundation
import Models

enum AccountDetailState {
  case loading
  case display(account: Account, featuredTags: [FeaturedTag], relationships: [Relationship])
  case error(error: Error)
}