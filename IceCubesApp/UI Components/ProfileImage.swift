//
//  ProfileImage.swift
//  IceCubesApp
//
//  Created by Matt Bonney on 11/21/22.
//

import SwiftUI
import Network

/// Supply this view with an Account to get the Async profile image.
struct ProfileImage: View {
    var account: Account
    var size: Double

    init(account: Account, size: Double) {
        self.account = account
        self.size = size
    }

    var body: some View {
        AsyncImage(url: account.avatar) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fit)
                .mask(RoundedRectangle(cornerRadius: (size * 0.25), style: .continuous))
        } placeholder: {
            ProgressView()
        }
        .frame(width: size, height: size)
    }
}

struct ProfileImage_Previews: PreviewProvider {
    static var previews: some View {
        ProfileImage(account: Account.preview, size: 44)
    }
}
