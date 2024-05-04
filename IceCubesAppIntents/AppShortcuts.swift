import AppIntents

struct AppShortcuts: AppShortcutsProvider {
  static var appShortcuts: [AppShortcut] {
    AppShortcut(
      intent: PostIntent(),
      phrases: [
        "Post \(\.$content) in \(.applicationName)",
        "Post a status on Mastodon with \(.applicationName)",
      ],
      shortTitle: "Compose a status",
      systemImageName: "square.and.pencil"
    )
    AppShortcut(
      intent: InlinePostIntent(),
      phrases: [
        "Write a status with \(.applicationName)",
        "Send on Status on Mastodon with \(.applicationName)",
      ],
      shortTitle: "Send a text status",
      systemImageName: "square.and.pencil"
    )
    AppShortcut(
      intent: TabIntent(),
      phrases: [
        "Open \(\.$tab) in \(.applicationName)",
        "Open \(.applicationName)",
      ],
      shortTitle: "Open Ice Cubes",
      systemImageName: "cube"
    )
    AppShortcut(
      intent: PostImageIntent(),
      phrases: [
        "Post images \(\.$images) in \(.applicationName)",
        "Send photos \(\.$images) with \(.applicationName)",
      ],
      shortTitle: "Post a status with an image",
      systemImageName: "photo"
    )
  }
}
