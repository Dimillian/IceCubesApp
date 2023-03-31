import Combine
import DesignSystem
import Env
import Models
import Network
import Status
import SwiftUI

class DisplaySettingsLocalColors: ObservableObject {
  @Published var tintColor = Theme.shared.tintColor
  @Published var primaryBackgroundColor = Theme.shared.primaryBackgroundColor
  @Published var secondaryBackgroundColor = Theme.shared.secondaryBackgroundColor
  @Published var labelColor = Theme.shared.labelColor

  private var subscriptions = Set<AnyCancellable>()

  init() {
    $tintColor
      .debounce(for: .seconds(0.5), scheduler: DispatchQueue.main)
      .sink(receiveValue: { newColor in Theme.shared.tintColor = newColor })
      .store(in: &subscriptions)
    $primaryBackgroundColor
      .debounce(for: .seconds(0.5), scheduler: DispatchQueue.main)
      .sink(receiveValue: { newColor in Theme.shared.primaryBackgroundColor = newColor })
      .store(in: &subscriptions)
    $secondaryBackgroundColor
      .debounce(for: .seconds(0.5), scheduler: DispatchQueue.main)
      .sink(receiveValue: { newColor in Theme.shared.secondaryBackgroundColor = newColor })
      .store(in: &subscriptions)
    $labelColor
      .debounce(for: .seconds(0.5), scheduler: DispatchQueue.main)
      .sink(receiveValue: { newColor in Theme.shared.labelColor = newColor })
      .store(in: &subscriptions)
  }
}

struct DisplaySettingsView: View {
  typealias FontState = Theme.FontState

  @Environment(\.colorScheme) private var colorScheme
  @EnvironmentObject private var theme: Theme
  @EnvironmentObject private var userPreferences: UserPreferences

  @StateObject private var localColors = DisplaySettingsLocalColors()

  @State private var isFontSelectorPresented = false
  @State var fontScale = 0.0
  @State var lineSpacing = 0.0

  private let previewStatusViewModel = StatusRowViewModel(status: Status.placeholder(forSettings: true, language: "la"),
                                                          client: Client(server: ""),
                                                          routerPath: RouterPath()) // translate from latin button

  var body: some View {
    ZStack(alignment: .top) {
      Form {
        StatusRowView(viewModel: { previewStatusViewModel })
          .allowsHitTesting(false)
          .opacity(0)
          .hidden()
        themeSection
        fontSection
        layoutSection
        platformsSection
        resetSection
      }
      .navigationTitle("settings.display.navigation-title")
      .scrollContentBackground(.hidden)
      .background(theme.secondaryBackgroundColor)
      examplePost
    }
  }

  private var examplePost: some View {
    VStack(spacing: 0) {
      StatusRowView(viewModel: { previewStatusViewModel })
        .allowsHitTesting(false)
        .padding(.layoutPadding)
        .background(theme.primaryBackgroundColor)
        .cornerRadius(8)
        .padding(.horizontal, .layoutPadding)
        .padding(.top, .layoutPadding)
        .background(theme.secondaryBackgroundColor)
      Rectangle()
        .fill(theme.secondaryBackgroundColor)
        .frame(height: 30)
        .mask(LinearGradient(gradient: Gradient(colors: [theme.secondaryBackgroundColor, .clear]),
                             startPoint: .top, endPoint: .bottom))
    }
  }

  private var themeSection: some View {
    Section {
      Toggle("settings.display.theme.systemColor", isOn: $theme.followSystemColorScheme)
      themeSelectorButton
      Group {
        ColorPicker("settings.display.theme.tint", selection: $localColors.tintColor)
        ColorPicker("settings.display.theme.background", selection: $localColors.primaryBackgroundColor)
        ColorPicker("settings.display.theme.secondary-background", selection: $localColors.secondaryBackgroundColor)
        ColorPicker("settings.display.theme.text-color", selection: $localColors.labelColor)
      }
      .disabled(theme.followSystemColorScheme)
      .opacity(theme.followSystemColorScheme ? 0.5 : 1.0)
      .onChange(of: theme.selectedSet) { _ in
        localColors.tintColor = theme.tintColor
        localColors.primaryBackgroundColor = theme.primaryBackgroundColor
        localColors.secondaryBackgroundColor = theme.secondaryBackgroundColor
        localColors.labelColor = theme.labelColor
      }
    } header: {
      Text("settings.display.section.theme")
    } footer: {
      if theme.followSystemColorScheme {
        Text("settings.display.section.theme.footer")
      }
    }
    .listRowBackground(theme.primaryBackgroundColor)
  }

  private var fontSection: some View {
    Section("settings.display.section.font") {
      Picker("settings.display.font", selection: .init(get: { () -> FontState in
        if theme.chosenFont?.fontName == "OpenDyslexic-Regular" {
          return FontState.openDyslexic
        } else if theme.chosenFont?.fontName == "AtkinsonHyperlegible-Regular" {
          return FontState.hyperLegible
        } else if theme.chosenFont?.fontName == ".AppleSystemUIFontRounded-Regular" {
          return FontState.SFRounded
        }
        return theme.chosenFontData != nil ? FontState.custom : FontState.system
      }, set: { newValue in
        switch newValue {
        case .system:
          theme.chosenFont = nil
        case .openDyslexic:
          theme.chosenFont = UIFont(name: "OpenDyslexic", size: 1)
        case .hyperLegible:
          theme.chosenFont = UIFont(name: "Atkinson Hyperlegible", size: 1)
        case .SFRounded:
          theme.chosenFont = UIFont.systemFont(ofSize: 1).rounded()
        case .custom:
          isFontSelectorPresented = true
        }
      })) {
        ForEach(FontState.allCases, id: \.rawValue) { fontState in
          Text(fontState.title).tag(fontState)
        }
      }
      .navigationDestination(isPresented: $isFontSelectorPresented, destination: { FontPicker() })

      VStack {
        Slider(value: $fontScale, in: 0.5 ... 1.5, step: 0.1) { editing in
          if !editing {
            theme.fontSizeScale = fontScale
          }
        }
        Text("settings.display.font.scaling-\(String(format: "%.1f", fontScale))")
          .font(.scaledBody)
      }
      .alignmentGuide(.listRowSeparatorLeading) { d in
        d[.leading]
      }
      .onAppear {
        fontScale = theme.fontSizeScale
      }

      VStack {
        Slider(value: $lineSpacing, in: 0.4 ... 10.0, step: 0.2) { editing in
          if !editing {
            theme.lineSpacing = lineSpacing
          }
        }
        Text("settings.display.font.line-spacing-\(String(format: "%.1f", lineSpacing))")
          .font(.scaledBody)
      }
      .alignmentGuide(.listRowSeparatorLeading) { d in
        d[.leading]
      }
      .onAppear {
        lineSpacing = theme.lineSpacing
      }
    }
    .listRowBackground(theme.primaryBackgroundColor)
  }

  private var layoutSection: some View {
    Section("settings.display.section.display") {
      Picker("settings.display.avatar.position", selection: $theme.avatarPosition) {
        ForEach(Theme.AvatarPosition.allCases, id: \.rawValue) { position in
          Text(position.description).tag(position)
        }
      }
      Picker("settings.display.avatar.shape", selection: $theme.avatarShape) {
        ForEach(Theme.AvatarShape.allCases, id: \.rawValue) { shape in
          Text(shape.description).tag(shape)
        }
      }
      Toggle("settings.display.full-username", isOn: $theme.displayFullUsername)
      Picker("settings.display.status.action-buttons", selection: $theme.statusActionsDisplay) {
        ForEach(Theme.StatusActionsDisplay.allCases, id: \.rawValue) { buttonStyle in
          Text(buttonStyle.description).tag(buttonStyle)
        }
      }

      Picker("settings.display.status.media-style", selection: $theme.statusDisplayStyle) {
        ForEach(Theme.StatusDisplayStyle.allCases, id: \.rawValue) { buttonStyle in
          Text(buttonStyle.description).tag(buttonStyle)
        }
      }
      Toggle("settings.display.translate-button", isOn: $userPreferences.showTranslateButton)
    }
    .listRowBackground(theme.primaryBackgroundColor)
  }

  @ViewBuilder
  private var platformsSection: some View {
    if UIDevice.current.userInterfaceIdiom == .phone {
      Section("iPhone") {
        Toggle("settings.display.show-tab-label", isOn: $userPreferences.showiPhoneTabLabel)
      }
      .listRowBackground(theme.primaryBackgroundColor)
    }

    if UIDevice.current.userInterfaceIdiom == .pad {
      Section("iPad") {
        Toggle("settings.display.show-ipad-column", isOn: $userPreferences.showiPadSecondaryColumn)
      }
      .listRowBackground(theme.primaryBackgroundColor)
    }
  }

  private var resetSection: some View {
    Section {
      Button {
        theme.followSystemColorScheme = true
        theme.selectedSet = colorScheme == .dark ? .iceCubeDark : .iceCubeLight
        theme.avatarShape = .rounded
        theme.avatarPosition = .top
        theme.statusActionsDisplay = .full

        localColors.tintColor = theme.tintColor
        localColors.primaryBackgroundColor = theme.primaryBackgroundColor
        localColors.secondaryBackgroundColor = theme.secondaryBackgroundColor
        localColors.labelColor = theme.labelColor

      } label: {
        Text("settings.display.restore")
      }
    }
    .listRowBackground(theme.primaryBackgroundColor)
  }

  private var themeSelectorButton: some View {
    NavigationLink(destination: ThemePreviewView()) {
      HStack {
        Text("settings.display.section.theme")
        Spacer()
        Text(theme.selectedSet.rawValue)
      }
    }
  }
}
