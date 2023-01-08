import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

public extension View {
    func applyTheme(_ theme: Theme) -> some View {
        modifier(ThemeApplier(theme: theme))
    }
}

struct ThemeApplier: ViewModifier {
    @ObservedObject var theme: Theme
    
    func body(content: Content) -> some View {
        content
            .tint(theme.tintColor)
            .preferredColorScheme(theme.selectedScheme == ColorScheme.dark ? .dark : .light)
            #if canImport(UIKit)
            .onAppear {
                setWindowTint(theme.tintColor)
                setWindowUserInterfaceStyle(theme.selectedScheme)
                setBarsColor(theme.primaryBackgroundColor)
            }
            .onChange(of: theme.tintColor) { newValue in
                setWindowTint(newValue)
            }
            .onChange(of: theme.selectedScheme) { newValue in
                setWindowUserInterfaceStyle(newValue)
            }
            .onChange(of: theme.primaryBackgroundColor) { newValue in
                setBarsColor(newValue)
            }
            #endif
    }
    
    #if canImport(UIKit)
    private func setWindowUserInterfaceStyle(_ colorScheme: ColorScheme) {
        allWindows()
            .forEach {
                switch colorScheme {
                case .dark:
                    $0.overrideUserInterfaceStyle = .dark
                case .light:
                    $0.overrideUserInterfaceStyle = .light
                }
            }
    }
    
    private func setWindowTint(_ color: Color) {
        allWindows()
            .forEach {
                $0.tintColor = UIColor(color)
            }
    }
    
    private func setBarsColor(_ color: Color) {
        UINavigationBar.appearance().isTranslucent = true
        UINavigationBar.appearance().barTintColor = UIColor(color)
    }
    
    private func allWindows() -> [UIWindow] {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
    }
    #endif
}
