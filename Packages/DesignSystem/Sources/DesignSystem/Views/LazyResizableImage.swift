//
//  LazyResizableImage.swift
//
//
//  Created by Hugo Saynac on 28/10/2023.
//

import Nuke
import NukeUI
import SwiftUI

/// A LazyImage (Nuke) with a geometry reader under the hood in order to use a Resize Processor to optimize performances on lists.
/// This views also allows smooth resizing of the images by debouncing the update of the ImageProcessor.
public struct LazyResizableImage<Content: View>: View {
  public init(url: URL?, @ViewBuilder content: @escaping (LazyImageState, GeometryProxy) -> Content) {
    imageURL = url
    self.content = content
  }

  let imageURL: URL?
  @State private var resizeProcessor: ImageProcessors.Resize?
  @State private var debouncedTask: Task<Void, Never>?

  @ViewBuilder
  private var content: (LazyImageState, _ proxy: GeometryProxy) -> Content

  public var body: some View {
    GeometryReader { proxy in
      LazyImage(url: imageURL) { state in
        content(state, proxy)
      }
      .processors([resizeProcessor == nil ? .resize(size: proxy.size) : resizeProcessor!])
      .onChange(of: proxy.size, initial: true) { oldValue, newValue in
        guard oldValue != newValue else { return }
        debouncedTask?.cancel()
        debouncedTask = Task {
          do { try await Task.sleep(for: .milliseconds(200)) } catch { return }
          resizeProcessor = .resize(size: newValue)
        }
      }
    }
  }
}
