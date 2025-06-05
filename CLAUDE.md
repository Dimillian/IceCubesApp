# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

IceCubesApp is a multiplatform Mastodon client built entirely in SwiftUI. It's an open-source native Apple application that runs on iOS, iPadOS, macOS, and visionOS.

## Build Commands

### Initial Setup
1. Clone the repository
2. Create your configuration file:
   ```bash
   cp IceCubesApp.xcconfig.template IceCubesApp.xcconfig
   ```
3. Edit `IceCubesApp.xcconfig` and add:
   - `DEVELOPMENT_TEAM` = Your Apple Developer Team ID
   - `BUNDLE_ID_PREFIX` = Your bundle identifier prefix (e.g., com.yourcompany)

### Building
- **Xcode GUI**: Open `IceCubesApp.xcodeproj` and build
- **Command Line**: `xcodebuild -scheme IceCubesApp build`

### Running Tests
- **All tests**: Run through Xcode's Test navigator
- **Specific package tests**:
  ```bash
  xcodebuild -scheme AccountTests test
  xcodebuild -scheme ModelsTests test
  xcodebuild -scheme NetworkTests test
  xcodebuild -scheme TimelineTests test
  xcodebuild -scheme EnvTests test
  ```
- **Swift Package Manager** (for individual packages):
  ```bash
  cd Packages/[PackageName]
  swift test
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

### No ViewModels - Use Native SwiftUI Data Flow
**New features MUST follow these patterns:**

1. **Views as Pure State Expressions**
   ```swift
   struct MyView: View {
       @Environment(MyService.self) private var service
       @State private var viewState: ViewState = .loading
       
       enum ViewState {
           case loading
           case loaded(data: [Item])
           case error(String)
       }
       
       var body: some View {
           // View is just a representation of its state
       }
   }
   ```

2. **Use Environment for Dependency Injection**
   - Services, clients, and shared state go in Environment
   - Access via `@Environment(ServiceType.self)`
   - Initialize at app level and inject down the view hierarchy

3. **Local State Management**
   - Use `@State` for view-specific state
   - Use `enum` for view states (loading, loaded, error)
   - Use `.task(id:)` and `.onChange(of:)` for side effects
   - Pass state between views using `@Binding`

4. **No ViewModels Required**
   - Views should be lightweight and disposable
   - Business logic belongs in services/clients
   - Test services independently, not views
   - Use SwiftUI previews for visual testing

5. **When Views Get Complex**
   - Split into smaller subviews
   - Use compound views that compose smaller views
   - Pass state via bindings between views
   - Never reach for a ViewModel as the solution

### Build Verification Process
**IMPORTANT**: When editing code, you MUST:

1. Build the project after making changes using XcodeBuildMCP commands
2. Fix any compilation errors before proceeding
3. Run relevant tests if modifying existing functionality

Example workflow:
```bash
# Build the main app
mcp__XcodeBuildMCP__build_mac_proj projectPath: "/path/to/IceCubesApp.xcodeproj" scheme: "IceCubesApp"

# Or for iOS simulator
mcp__XcodeBuildMCP__build_ios_sim_name_proj projectPath: "/path/to/IceCubesApp.xcodeproj" scheme: "IceCubesApp" simulatorName: "iPhone 16"
```

### Code Style When Editing
- Maintain existing patterns in legacy code
- New features use modern patterns exclusively
- Prefer composition over inheritance
- Keep views focused and single-purpose
- Use descriptive names for state enums

## Development Requirements
- Minimum Swift 6.0
- Minimum deployment: iOS 17.0, visionOS 1.0
- Xcode 15.0 or later
- Apple Developer account for device testing