//
//  UserAccountView.swift
//  IceCubesApp
//
//  Created by Matt Bonney on 11/21/22.
//

import SwiftUI
import Network

enum UserAccountTabs: String, CaseIterable, Identifiable {
    var id: String { self.rawValue }
    case posts, replies, media, about
}

struct UserAccountView: View {
    var account: Account

    @State private var tab: UserAccountTabs = .posts

    var body: some View {
        List {
            // User info
            Section {
                headerImage()
                    .listRowInsets(EdgeInsets())

                HStack {
                    ProfileImage(account: account, size: 60)

                    VStack(alignment: .leading) {
                        Text(account.displayName)
                            .font(.headline)

                        Text(account.username)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Text("This is my profile text, describing what I do and who I am.")
                    .listRowSeparator(.hidden)

                followerCounts()
            }

            Section {
                Picker(selection: $tab) {
                    ForEach(UserAccountTabs.allCases) { profileTab in
                        Text(profileTab.rawValue.capitalized)
                            .tag(profileTab)
                    }
                } label: {
                    Text("View...")
                }
                .pickerStyle(.segmented)
            }
            .listSectionSeparator(.hidden, edges: .all)

            // User posts
            Section {
                feedTab(for: tab)
            }
        }
        .listStyle(.plain)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button { } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                Button { } label: {
                    Image(systemName: "ellipsis.circle")
                }

            }
        }
    }

    func headerImage() -> some View {
        // @TODO: Need header image URL from API.
        LinearGradient(colors: [.blue, .indigo], startPoint: .top, endPoint: .bottom)
            .frame(height: 200)
    }

    func followerCounts() -> some View {
        Grid {
            GridRow {
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("300").font(.headline)
                    Text("posts").font(.caption)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("100").font(.headline)
                    Text("following").font(.caption)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("200").font(.headline)
                    Text("followers").font(.caption)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    @ViewBuilder func feedTab(for tab: UserAccountTabs) -> some View {
        switch tab {
        case .posts:
            Text("Posts")
        case .replies:
            Text("Posts & Replies")
        case .media:
            Text("Media")
        case .about:
            Text("About")
        }
    }

}

struct UserAccountView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            UserAccountView(account: Account.preview)
        }
    }
}
//
//
//VStack(alignment: .leading) {
//    HStack {
//        AsyncImage(
//            url: status.account.avatar,
//            content: { image in
//                image.resizable()
//                    .aspectRatio(contentMode: .fit)
//                    .cornerRadius(13)
//                    .frame(maxWidth: 26, maxHeight: 26)
//            },
//            placeholder: {
//                ProgressView()
//            }
//        )
//        Text(status.account.username)
//    }
//    Text(status.content)
//}
//}
