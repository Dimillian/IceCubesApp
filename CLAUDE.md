# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

IceCubesApp is a multiplatform Mastodon client built entirely in SwiftUI. It's an open-source native Apple application that runs on iOS, iPadOS, macOS, and visionOS.

## Build Commands

### Building for iOS Simulator
To build IceCubesApp for iPhone Air simulator:
```bash
mcp__XcodeBuildMCP__build_sim_name_proj projectPath: "/Users/thomas/Documents/Dev/Open Source/IceCubesApp/IceCubesApp.xcodeproj" scheme: "IceCubesApp" simulatorName: "iPhone Air"
```


### Running Tests
- **All tests**: Run through Xcode's Test navigator
- **Specific package tests (XcodeBuildMCP on simulator)**:
  ```bash
  # Set defaults once per session
  mcp__XcodeBuildMCP__session-set-defaults projectPath: "/Users/thomas/Documents/Dev/Open Source/IceCubesApp/IceCubesApp.xcodeproj" simulatorName: "iPhone Air"

  # Then run any package test scheme
  mcp__XcodeBuildMCP__test_sim scheme: "AccountTests"
  mcp__XcodeBuildMCP__test_sim scheme: "ModelsTests"
  mcp__XcodeBuildMCP__test_sim scheme: "NetworkTests"
  mcp__XcodeBuildMCP__test_sim scheme: "TimelineTests"
  mcp__XcodeBuildMCP__test_sim scheme: "EnvTests"
  ```

### Code Formatting
The project uses SwiftFormat with 2-space indentation. Configuration is in `.swiftformat`.

## Architecture

### Modular Package Structure
The app is organized into Swift Packages under `/Packages/`:

- **Models**: Data models and API structures for Mastodon entities
- **Network**: API client implementation with support for Mastodon, DeepL, and OpenAI APIs
- **Env**: Environment objects, app-wide state, and dependency injection
- **DesignSystem**: Theming, colors, fonts, and reusable UI components
- **Account**: User profile views and account management
- **Timeline**: Timeline views, filtering, and unread status tracking
- **StatusKit**: Status/post composition and display components
- **Notifications**: Notification views and handling
- **MediaUI**: Media viewing with zoom, video playback, and sharing

### Key Architectural Patterns (Legacy)
The codebase contains legacy MVVM patterns, but **new features should NOT use ViewModels**.

- **Legacy**: Some older views still use ViewModels (being phased out)
- **Modern Approach**: Views as pure state expressions using SwiftUI primitives
- **Environment Objects**: Used for dependency injection (Router, CurrentAccount, Theme, etc.)
- **Swift Concurrency**: Async/await throughout for API calls
- **Observation Framework**: Uses `@Observable` for services injected via Environment

### App Extensions
- **NotificationService**: Handles push notification decryption and formatting
- **ShareExtension**: Enables sharing content to the app
- **ActionExtension**: Quick actions from share sheet
- **WidgetsExtension**: Home screen widgets for timeline, mentions, and accounts

### Important Implementation Details
- **Multi-account**: Managed through `AppAccountsManager` with secure storage
- **Push Notifications**: Custom proxy server implementation for privacy
- **Theme System**: Extensive customization with 40+ app icons
- **Translation**: Supports DeepL API and instance-provided translations
- **AI Features**: OpenAI integration for alt text generation

## Modern SwiftUI Architecture Guidelines (2025)

### Core Philosophy

- SwiftUI is the default UI paradigm - embrace its declarative nature
- Avoid legacy UIKit patterns and unnecessary abstractions
- Focus on simplicity, clarity, and native data flow
- Let SwiftUI handle the complexity - don't fight the framework
- **No ViewModels** - Use native SwiftUI data flow patterns

### Architecture Principles

#### 1. Native State Management

Use SwiftUI's built-in property wrappers appropriately:
- `@State` - Local, ephemeral view state
- `@Binding` - Two-way data flow between views
- `@Observable` - Shared state (preferred for new code)
- `@Environment` - Dependency injection for app-wide concerns

#### 2. State Ownership

- Views own their local state unless sharing is required
- State flows down, actions flow up
- Keep state as close to where it's used as possible
- Extract shared state only when multiple views need it

Example:
```swift
struct TimelineView: View {
    @Environment(Client.self) private var client
    @State private var viewState: ViewState = .loading

    enum ViewState {
        case loading
        case loaded(statuses: [Status])
        case error(Error)
    }

    var body: some View {
        Group {
            switch viewState {
            case .loading:
                ProgressView()
            case .loaded(let statuses):
                StatusList(statuses: statuses)
            case .error(let error):
                ErrorView(error: error)
            }
        }
        .task {
            await loadTimeline()
        }
    }

    private func loadTimeline() async {
        do {
            let statuses = try await client.getHomeTimeline()
            viewState = .loaded(statuses: statuses)
        } catch {
            viewState = .error(error)
        }
    }
}
```

#### 3. Modern Async Patterns

- Use `async/await` as the default for asynchronous operations
- Leverage `.task` modifier for lifecycle-aware async work
- Handle errors gracefully with try/catch
- Avoid Combine unless absolutely necessary

#### 4. View Composition

- Build UI with small, focused views
- Extract reusable components naturally
- Use view modifiers to encapsulate common styling
- Prefer composition over inheritance

#### 5. Code Organization

- Organize by feature (e.g., Timeline/, Account/, Settings/)
- Keep related code together in the same file when appropriate
- Use extensions to organize large files
- Follow Swift naming conventions consistently

### Build Verification Process
**IMPORTANT**: When editing code, you MUST:

1. Build the project after making changes using XcodeBuildMCP commands
2. Fix any compilation errors before proceeding
3. Run relevant tests if modifying existing functionality
4. Ensure code follows modern SwiftUI patterns

Example workflow:
```bash
# Build the main app
mcp__XcodeBuildMCP__build_mac_proj projectPath: "/path/to/IceCubesApp.xcodeproj" scheme: "IceCubesApp"

# Or for iOS simulator
mcp__XcodeBuildMCP__build_ios_sim_name_proj projectPath: "/path/to/IceCubesApp.xcodeproj" scheme: "IceCubesApp" simulatorName: "iPhone Air"
```

### Implementation Examples

#### Shared State with @Observable
```swift
@Observable
class AppAccountsManager {
    var currentAccount: Account?
    var availableAccounts: [Account] = []

    func switchAccount(_ account: Account) {
        currentAccount = account
        // Handle account switching
    }
}

// In App file
struct IceCubesApp: App {
    @State private var accountManager = AppAccountsManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(accountManager)
        }
    }
}
```

#### Modern Async Data Loading
```swift
struct NotificationsView: View {
    @Environment(Client.self) private var client
    @State private var notifications: [Notification] = []
    @State private var isLoading = false
    @State private var error: Error?

    var body: some View {
        List(notifications) { notification in
            NotificationRow(notification: notification)
        }
        .overlay {
            if isLoading {
                ProgressView()
            }
        }
        .task {
            await loadNotifications()
        }
        .refreshable {
            await loadNotifications()
        }
    }

    private func loadNotifications() async {
        isLoading = true
        defer { isLoading = false }

        do {
            notifications = try await client.getNotifications()
        } catch {
            self.error = error
        }
    }
}
```

### Best Practices

#### DO:
- Write self-contained views when possible
- Use property wrappers as intended by Apple
- Test logic in isolation, preview UI visually
- Handle loading and error states explicitly
- Keep views focused on presentation
- Use Swift's type system for safety
- Trust SwiftUI's update mechanism

#### DON'T:
- Create ViewModels for every view
- Move state out of views unnecessarily
- Add abstraction layers without clear benefit
- Use Combine for simple async operations
- Fight SwiftUI's update mechanism
- Overcomplicate simple features
- **Nest @Observable objects within other @Observable objects** - This breaks SwiftUI's observation system. Initialize services at the view level instead.

### Testing Strategy

- Unit test business logic in services/clients
- Use SwiftUI Previews for visual testing
- Test @Observable classes independently
- Keep tests simple and focused
- Don't sacrifice code clarity for testability

### Code Style When Editing
- Maintain existing patterns in legacy code
- New features use modern patterns exclusively
- Prefer composition over inheritance
- Keep views focused and single-purpose
- Use descriptive names for state enums
- Write SwiftUI code that looks and feels like SwiftUI

## Development Requirements
- Minimum Swift 6.0
- iOS 26 SDK (June 2025)
- Minimum deployment: iOS 18.0, visionOS 1.0
- Xcode 16.0 or later with iOS 26 SDK
- Apple Developer account for device testing

## iOS 26 SDK Integration

**IMPORTANT**: The project now supports iOS 26 SDK (June 2025) while maintaining iOS 18 as the minimum deployment target. Use `#available` checks when adopting iOS 26+ APIs.

### Available iOS 26 SwiftUI APIs

#### Liquid Glass Effects
- `glassEffect(_:in:isEnabled:)` - Apply Liquid Glass effects to views
- `buttonStyle(.glass)` - Apply Liquid Glass styling to buttons
- `ToolbarSpacer` - Create visual breaks in toolbars with Liquid Glass

Example:
```swift
Button("Post", action: postStatus)
    .buttonStyle(.glass)
    .glassEffect(.thin, in: .rect(cornerRadius: 12))
```

#### Enhanced Scrolling
- `scrollEdgeEffectStyle(_:for:)` - Configure scroll edge effects
- `backgroundExtensionEffect()` - Duplicate, mirror, and blur views around edges

#### Tab Bar Enhancements
- `tabBarMinimizeBehavior(_:)` - Control tab bar minimization behavior
- Search role for tabs with search field replacing tab bar
- `TabViewBottomAccessoryPlacement` - Adjust accessory view content based on placement

#### Web Integration
- `WebView` and `WebPage` - Full control over browsing experience

#### Drag and Drop
- `draggable(_:_:)` - Drag multiple items
- `dragContainer(for:id:in:selection:_:)` - Container for draggable views

#### Animation
- `@Animatable` macro - SwiftUI synthesizes custom animatable data properties

#### UI Components
- `Slider` with automatic tick marks when using step parameter
- `windowResizeAnchor(_:)` - Set window anchor point for resizing

#### Text Enhancements
- `TextEditor` now supports `AttributedString`
- `AttributedTextSelection` - Handle text selection with attributed text
- `AttributedTextFormattingDefinition` - Define text styling in specific contexts
- `FindContext` - Create find navigator in text editing views

#### Accessibility
- `AssistiveAccess` - Support Assistive Access in iOS/iPadOS scenes

#### HDR Support
- `Color.ResolvedHDR` - RGBA values with HDR headroom information

#### UIKit Integration
- `UIHostingSceneDelegate` - Host and present SwiftUI scenes in UIKit
- `NSHostingSceneRepresentation` - Host SwiftUI scenes in AppKit
- `NSGestureRecognizerRepresentable` - Incorporate gesture recognizers from AppKit

#### Immersive Spaces (visionOS)
- `manipulable(coordinateSpace:operations:inertia:isEnabled:onChanged:)` - Hand gesture manipulation
- `SurfaceSnappingInfo` - Snap volumes and windows to surfaces
- `RemoteImmersiveSpace` - Render stereo content from Mac to Apple Vision Pro
- `SpatialContainer` - 3D layout container
- Depth-based modifiers: `aspectRatio3D(_:contentMode:)`, `rotation3DLayout(_:)`, `depthAlignment(_:)`

### Usage Guidelines
- Use `#available(iOS 26, *)` for iOS 26-only features
- Replace legacy implementations with iOS 26 APIs where appropriate
- Leverage Liquid Glass effects for modern UI aesthetics in timeline and status views
- Use enhanced text capabilities for the status composer
- Apply new drag-and-drop APIs for media and status interactions
