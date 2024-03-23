import SwiftUI
#if canImport(UIKit)
  import UIKit
#endif

public extension View {
  @MainActor func applyTheme(_ theme: Theme) -> some View {
    modifier(ThemeApplier(theme: theme))
  }
}

@MainActor
struct ThemeApplier: ViewModifier {
  @Environment(\EnvironmentValues.colorScheme) var colorScheme

  var theme: Theme

  var actualColorScheme: SwiftUI.ColorScheme? {
    if theme.followSystemColorScheme {
      return nil
    }
    return theme.selectedScheme == ColorScheme.dark ? .dark : .light
  }

  func body(content: Content) -> some View {
    content
      .tint(theme.tintColor)
      .preferredColorScheme(actualColorScheme)
    #if canImport(UIKit)
      .onAppear {
        // If theme is never set before set the default store. This should only execute once after install.
        if !theme.isThemePreviouslySet {
          theme.applySet(set: colorScheme == .dark ? .iceCubeDark : .iceCubeLight)
          theme.isThemePreviouslySet = true
        } else if theme.followSystemColorScheme, theme.isThemePreviouslySet,
                  let sets = availableColorsSets
                  .first(where: { $0.light.name == theme.selectedSet || $0.dark.name == theme.selectedSet })
        {
          theme.applySet(set: colorScheme == .dark ? sets.dark.name : sets.light.name)
        }
        setWindowTint(theme.tintColor)
        setWindowUserInterfaceStyle(from: theme.selectedScheme)
        setBarsColor(theme.primaryBackgroundColor)
      }
      .onChange(of: theme.tintColor) { _, newValue in
        setWindowTint(newValue)
      }
      .onChange(of: theme.primaryBackgroundColor) { _, newValue in
        setBarsColor(newValue)
      }
      .onChange(of: theme.selectedScheme) { _, newValue in
        setWindowUserInterfaceStyle(from: newValue)
      }
      .onChange(of: colorScheme) { _, newColorScheme in
        if theme.followSystemColorScheme,
           let sets = availableColorsSets
           .first(where: { $0.light.name == theme.selectedSet || $0.dark.name == theme.selectedSet })
        {
          theme.applySet(set: newColorScheme == .dark ? sets.dark.name : sets.light.name)
        }
      }
    #endif
  }

  #if canImport(UIKit)
    private func setWindowUserInterfaceStyle(from colorScheme: ColorScheme) {
      guard !theme.followSystemColorScheme else {
        setWindowUserInterfaceStyle(.unspecified)
        return
      }
      switch colorScheme {
      case .dark:
        setWindowUserInterfaceStyle(.dark)
      case .light:
        setWindowUserInterfaceStyle(.light)
      }
    }

    private func setWindowUserInterfaceStyle(_ userInterfaceStyle: UIUserInterfaceStyle) {
      for window in allWindows() {
        window.overrideUserInterfaceStyle = userInterfaceStyle
      }
    }

    private func setWindowTint(_ color: Color) {
      for window in allWindows() {
        window.tintColor = UIColor(color)
      }
    }

    private func setBarsColor(_ color: Color) {
      UINavigationBar.appearance().isTranslucent = true
      UINavigationBar.appearance().barTintColor = UIColor(color)
    }

    private func allWindows() -> [UIWindow] {
      UIApplication.shared.connectedScenes
        .compactMap { $0 as? UIWindowScene }
        .flatMap(\.windows)
    }
  #endif
}
