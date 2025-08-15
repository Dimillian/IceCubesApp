import AppIntents

struct AppShortcuts: AppShortcutsProvider {
  static var appShortcuts: [AppShortcut] {
    AppShortcut(
      intent: PostIntent(),
      phrases: [
        "Post in \(.applicationName)",
        "Post a status on Mastodon with \(.applicationName)",
      ],
      shortTitle: "Compose a post",
      systemImageName: "square.and.pencil"
    )
    AppShortcut(
      intent: InlinePostIntent(),
      phrases: [
        "Write a post with \(.applicationName)",
        "Send on post on Mastodon with \(.applicationName)",
      ],
      shortTitle: "Send a post",
      systemImageName: "square.and.pencil"
    )
    AppShortcut(
      intent: InlinePostImageIntent(),
      phrases: [
        "Send images with \(.applicationName)",
        "Send an image with \(.applicationName)",
        "Post photos on Mastodon with \(.applicationName)",
      ],
      shortTitle: "Send image(s) (background)",
      systemImageName: "photo.on.rectangle.angled"
    )
    AppShortcut(
      intent: TabIntent(),
      phrases: [
        "Open \(.applicationName)"
      ],
      shortTitle: "Open Ice Cubes",
      systemImageName: "cube"
    )
    AppShortcut(
      intent: PostImageIntent(),
      phrases: [
        "Post images in \(.applicationName)",
        "Post an image in \(.applicationName)",
        "Send photos with \(.applicationName)",
        "Send a photo with \(.applicationName)",
      ],
      shortTitle: "Post a status with an image",
      systemImageName: "photo"
    )
  }
}
