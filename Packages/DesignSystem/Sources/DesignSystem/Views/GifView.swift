//
//  GifView.swift
//  DesignSystem
//
//  Created by Robert George on 10/26/25.
//

import Env
import Gifu
import SwiftUI

public struct GifView: UIViewRepresentable {
  @Environment(UserPreferences.self) private var preferences
  @Environment(Theme.self) private var theme

  let animatedView = GIFImageView()
  var data: Data

  public init(data: Data) {
    self.data = data
  }

  public func makeUIView(context: UIViewRepresentableContext<GifView>) -> UIView {
    let view = UIView()

    animatedView.prepareForAnimation(withGIFData: data)
    animatedView.contentMode = .scaleAspectFit

    animatedView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(animatedView)

    if theme.avatarAnimated {
      animatedView.startAnimatingGIF()
    }

    NSLayoutConstraint.activate([
      animatedView.heightAnchor.constraint(equalTo: view.heightAnchor),
      animatedView.widthAnchor.constraint(equalTo: view.widthAnchor),
    ])

    return view
  }

  public func updateUIView(_ uiView: UIView, context: Context) {

  }

}
