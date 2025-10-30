//
//  GifView.swift
//  DesignSystem
//
//  Created by Robert George on 10/26/25.
//

import SwiftUI
import Gifu
import Env

public struct GifView: UIViewRepresentable {
    let animatedView = GIFImageView()
    var data : Data
    @Environment(UserPreferences.self) private var preferences
    @Environment(Theme.self) private var theme

    public init(data: Data) {
        self.data = data
    }
    
    public func makeUIView(context: UIViewRepresentableContext<GifView>) -> UIView {
        let view = UIView()
        
        animatedView.prepareForAnimation(withGIFData: data)

        animatedView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(animatedView)
        
        if theme.avatarAnimated {
            animatedView.startAnimatingGIF()
        }
        
        NSLayoutConstraint.activate([
            animatedView.heightAnchor.constraint(equalTo: view.heightAnchor),
            animatedView.widthAnchor.constraint(equalTo: view.widthAnchor)
        ])
        
        return view
    }
    
    public func updateUIView(_ uiView: UIView, context: Context) {
        
    }

}
