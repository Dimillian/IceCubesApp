import Foundation
import SwiftUI

@MainActor
public enum DeepLUserAPIHandler {
  private static let service = "API Token", account = "DeepL"
  
  public static func write(value: String) {
    if !value.isEmpty {
      KeychainHelper.save(value, service: service, account: account, syncable: true)
    } else {
      KeychainHelper.delete(service: service, account: account, syncable: true)
    }
  }
  
  public static func writeAndUpdate(value: String) {
    write(value: value)
    
    let optValue = !value.isEmpty ? value : nil
    updatePreferences(value: optValue)
  }
  
  private static func readInternal() -> String? {
    KeychainHelper.read(service: service, account: account, type: String.self, syncable: true)
  }

  private static func returnIfAllowed(value: String?) -> String? {
    guard UserPreferences.shared.alwaysUseDeepl else {return nil}
    
    return value
  }
  
  private static func updatePreferences(value: String?) {
    let oldVal = UserPreferences.shared.alwaysUseDeepl
    UserPreferences.shared.alwaysUseDeepl = oldVal && value != nil
  }
  
  public static func updatePreferences() {
    updatePreferences(value: readInternal())
  }

  public static func read() -> String? {
    returnIfAllowed(value: readInternal())
  }
  
  public static func readAndUpdate() -> String? {
    let value = readInternal()
    updatePreferences(value: value)
    return returnIfAllowed(value: value)
  }
}
