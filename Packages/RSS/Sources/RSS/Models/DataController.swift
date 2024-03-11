//
//  RSSDataController.swift
//
//
//  Created by Duong Thai on 05/03/2024.
//

import CoreData

@MainActor
public class RSSDataController {
  private static let modelName = "RSSModel"

  public let container: NSPersistentContainer
  public static let shared = RSSDataController()

  private init() {
    guard
      let modelURL = Bundle
        .module
        .url(forResource: Self.modelName, withExtension: "momd")
    else {
      fatalError("Failed to get \(Self.modelName)'s URL.")
    }

    guard let mom = NSManagedObjectModel(contentsOf: modelURL) else {
      fatalError("Failed to initialize NSManagedObjectModel from: \(modelURL)")
    }

    self.container = NSPersistentContainer(name: Self.modelName, managedObjectModel: mom)
    self.container.loadPersistentStores { _, error in
      if let error {
        fatalError("Core Data failed to load Persistent Stores:\(error.localizedDescription)")
      }
    }
    self.container.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyStoreTrump
  }
}
