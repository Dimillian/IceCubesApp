//
//  IconView.swift
//  IconGallery
//
//  Created by Matt Bonney on 10/16/23.
//

import SwiftUI

struct IconView: View {
    var filename: String
    private let cornerRadius: CGFloat = 20.0

    init(_ icon: AppIcon) {
        self.filename = icon.iconName
    }

    init(filename: String) {
        self.filename = filename
    }

    var body: some View {
        if let uiImage = UIImage(named: filename, in: .module, with: .none) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .clipShape(.rect(cornerRadius: cornerRadius))
                .shadow(radius: 4)
                .overlay {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(.tertiary, lineWidth: 1.0)
                }
        } else {
            Color.clear
        }
    }
}

#Preview {
    IconView(.primary)
}
