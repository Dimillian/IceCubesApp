import Foundation
import Models
import SwiftUI
import LRUCache
import Env

public class ReblogCache {

  struct CacheEntry {
    var reblogId:String
    var postId:String
    var seen:Bool
  }

  static public let shared = ReblogCache()
  var statusCache = LRUCache<String, CacheEntry>()

  init() {
    statusCache.countLimit = 100  // can tune the cache here this is super conservative
  }
  
  

  @MainActor public func removeDuplicateReblogs(_ statuses: inout [Status]) {
    
    print ("Deduping \(statuses.count) statuses")

    var i = statuses.count
    let ct = statuses.count

    for status in statuses.reversed() { // go backwards cache the earliest reblog
      
      i -= 1
      if let reblog = status.reblog {
        
        if let cached = statusCache.value(forKey: reblog.id) {
          
          // this is already cached
          // if the reblogged post is in the cache and we have actually seen it
          // then we will suppress it so long as the status id on
          // this post is not the status id that we cached as seen already
          if cached.postId != status.id && !cached.seen {
            
            // Unless it happens to be our user that reblogged it.  Then it
            // would be weird if it didn't reappear
            if status.account.id != CurrentAccount.shared.account?.id {
              print("suppressing: \(reblog.id)/ \(reblog.account.displayName) by \(status.account.displayName)")
              
              statuses.remove(at: i)
              assert(statuses.count == (ct-1))
              cache(status, seen:false)
              
            }
            else {
              print("keeping my reblog: \(reblog.id)/ \(reblog.account.displayName) by \(status.account.displayName)")
              cache(status, seen:true)
            }
          }
          else {
            print("keeping seen item: \(reblog.id)/ \(reblog.account.displayName) by \(status.account.displayName)")
            cache(status, seen:false)
          }
          
        }
        else {
          print("caching new item: \(reblog.id)/ \(reblog.account.displayName) by \(status.account.displayName)")
          cache(status, seen:false)
        }
        
      }
      else {
        print("Not boost")
      }
      
    }
  }

  public func cache(_ status:Status, seen:Bool) {

    var wasSeen = false
    var postToCache = status.id

    if let reblog = status.reblog {
      // only caching boosts at the moment.
      
      if(seen) {
        print("SEEN: \(reblog.id)/ \(reblog.account.displayName) by \(status.account.displayName)")
      }
      
      if let cached = statusCache.value(forKey: reblog.id) {
        // every time we see it, we refresh it in the list
        // so poplular things are kept in the cache
        
        wasSeen = cached.seen
        
        if wasSeen {
          postToCache = cached.postId
          // if we have seen a particular version of the post
          // that's the one we keep
          print("already seen")

        }

        print("re-up: \(reblog.id)/ \(reblog.account.displayName)")
      }
      else {
        print("NEW!: \(reblog.id)/ \(reblog.account.displayName)")
      }

      statusCache.setValue(CacheEntry(reblogId: reblog.id, postId: postToCache, seen: seen || wasSeen), forKey: reblog.id)

    }
    
  }
}
