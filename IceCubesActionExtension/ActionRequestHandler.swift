//
//  ActionRequestHandler.swift
//  IceCubesActionExtension
//
//  Created by Thomas Durand on 26/01/2023.
//

import UIKit
import MobileCoreServices
import UniformTypeIdentifiers

// Sample code was sending this from a thread to another, let asume @Sendable for this
extension NSExtensionContext: @unchecked Sendable { }

class ActionRequestHandler: NSObject, NSExtensionRequestHandling {
    enum Error: Swift.Error {
        case inputProviderNotFound
        case loadedItemHasWrongType
        case urlNotFound
        case notMastodonInstance
    }

    func beginRequest(with context: NSExtensionContext) {
        // Do not call super in an Action extension with no user interface
        Task {
            do {
                let url = try await url(from: context)
                guard try await url.isMastodonInstance() else {
                    throw Error.notMastodonInstance
                }
                await MainActor.run {
                    let output = output(wrapping: url.iceCubesAppDeepLink)
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
    func isMastodonInstance() async throws -> Bool {
        let host = host()!
        let url = URL(string: "https://\(host)/api/v2/instance")!
        let request = URLRequest(url: url)
        let (_, response) = try await URLSession(configuration: .default).data(for: request)
        guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
            return false
        }
        return true
    }

    var iceCubesAppDeepLink: URL {
        URL(string: absoluteString.replacing("https://", with: "icecubesapp://"))!
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
