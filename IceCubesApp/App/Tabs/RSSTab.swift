//
//  RSSTab.swift
//  IceCubesApp
//
//  Created by Duong Thai on 26/02/2024.
//

import SwiftUI
import RSS
import Env

@MainActor
public struct RSSTab: View {
  @State private var routerPath = RouterPath()

  public var body: some View {
    RSSTabContentView()
      .withSheetDestinations(sheetDestinations: $routerPath.presentedSheet)
      .withSafariRouter()
      .environment(routerPath)
  }
}
