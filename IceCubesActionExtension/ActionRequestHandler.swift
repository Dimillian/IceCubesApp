//
//  ActionRequestHandler.swift
//  IceCubesActionExtension
//
//  Created by Thomas Durand on 26/01/2023.
//

import MobileCoreServices
import UIKit
import UniformTypeIdentifiers

import Models
import Network

// Sample code was sending this from a thread to another, let asume @Sendable for this
extension NSExtensionContext: @unchecked Sendable {}

final class ActionRequestHandler: NSObject, NSExtensionRequestHandling, Sendable {
  enum Error: Swift.Error {
    case inputProviderNotFound
    case loadedItemHasWrongType
    case urlNotFound
    case noHost
    case notMastodonInstance
  }

  func beginRequest(with context: NSExtensionContext) {
    // Do not call super in an Action extension with no user interface
    Task {
      do {
        let url = try await url(from: context)
        guard await url.isMastodonInstance else {
          throw Error.notMastodonInstance
        }
        await MainActor.run {
          let deeplink = url.iceCubesAppDeepLink
          let output = output(wrapping: deeplink)
          context.completeRequest(returningItems: output)
        }
      } catch {
        await MainActor.run {
          context.completeRequest(returningItems: [])
        }
      }
    }
  }
}

extension URL {
  var isMastodonInstance: Bool {
    get async {
      do {
        guard let host = host() else {
          throw ActionRequestHandler.Error.noHost
        }
        let _: Instance = try await Client(server: host).get(endpoint: Instances.instance)
        return true
      } catch {
        return false
      }
    }
  }

  var iceCubesAppDeepLink: URL {
    var components = URLComponents(url: self, resolvingAgainstBaseURL: false)!
    components.scheme = AppInfo.scheme.trimmingCharacters(in: [":", "/"])
    return components.url!
  }
}

extension ActionRequestHandler {
  /// Will look for an input item that might provide the property list that Javascript sent us
  private func url(from context: NSExtensionContext) async throws -> URL {
    for item in context.inputItems as! [NSExtensionItem] {
      guard let attachments = item.attachments else {
        continue
      }
      for itemProvider in attachments {
        guard itemProvider.hasItemConformingToTypeIdentifier(UTType.propertyList.identifier) else {
          continue
        }
        guard let dictionary = try await itemProvider.loadItem(forTypeIdentifier: UTType.propertyList.identifier) as? [String: Any] else {
          throw Error.loadedItemHasWrongType
        }
        let input = dictionary[NSExtensionJavaScriptPreprocessingResultsKey] as! [String: Any]? ?? [:]
        guard let absoluteStringUrl = input["url"] as? String, let url = URL(string: absoluteStringUrl) else {
          throw Error.urlNotFound
        }
        return url
      }
    }
    throw Error.inputProviderNotFound
  }

  /// Wrap the output to the expected object so we send back results to JS
  private func output(wrapping deeplink: URL) -> [NSExtensionItem] {
    let results = ["deeplink": deeplink.absoluteString]
    let dictionary = [NSExtensionJavaScriptFinalizeArgumentKey: results]
    let provider = NSItemProvider(item: dictionary as NSDictionary, typeIdentifier: UTType.propertyList.identifier)
    let item = NSExtensionItem()
    item.attachments = [provider]
    return [item]
  }
}
