import TelemetryDeck
import SwiftUI

@MainActor
public class Telemetry {
  static var userId: String? {
    CurrentAccount.shared.account?.id
  }
  
  public static func setup() {
    let config = TelemetryDeck.Config(appID: "F04175D2-599A-4504-867E-CE870B991EB7")
    TelemetryDeck.initialize(config: config)
  }
  
  
  public static func signal(_ event: String, parameters: [String: String] = [:]) {
    TelemetryDeck.signal(event, parameters: parameters, customUserID: userId)
  }
}
