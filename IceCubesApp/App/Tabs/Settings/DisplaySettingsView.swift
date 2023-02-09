import DesignSystem
import Env
import Models
import Status
import SwiftUI

struct DisplaySettingsView: View {
  typealias FontState = Theme.FontState

  @Environment(\.colorScheme) private var colorScheme
  @EnvironmentObject private var theme: Theme
  @EnvironmentObject private var userPreferences: UserPreferences

  @State private var isFontSelectorPresented = false

  private var previewStatusViewModel = StatusRowViewModel(status: Status.placeholder(parseMarkdown: true))

  var body: some View {
    Form {
      Section("settings.display.example-toot") {
        StatusRowView(viewModel: previewStatusViewModel)
          .allowsHitTesting(false)
      }

      Section {
        Toggle("settings.display.theme.systemColor", isOn: $theme.followSystemColorScheme)
        themeSelectorButton
        Group {
          ColorPicker("settings.display.theme.tint", selection: $theme.tintColor)
          ColorPicker("settings.display.theme.background", selection: $theme.primaryBackgroundColor)
          ColorPicker("settings.display.theme.secondary-background", selection: $theme.secondaryBackgroundColor)
        }
        .disabled(theme.followSystemColorScheme)
        .opacity(theme.followSystemColorScheme ? 0.5 : 1.0)
      } header: {
        Text("settings.display.section.theme")
      } footer: {
        if theme.followSystemColorScheme {
          Text("settings.display.section.theme.footer")
        }
      }
      .listRowBackground(theme.primaryBackgroundColor)
      
      Section("settings.display.section.display") {
        Picker("settings.display.font", selection: .init(get: { () -> FontState in
          if userPreferences.chosenFont?.fontName == "OpenDyslexic-Regular" {
            return FontState.openDyslexic
          } else if  userPreferences.chosenFont?.fontName == "AtkinsonHyperlegible-Regular" {
            return FontState.hyperLegible
          }
          return userPreferences.chosenFontData != nil ? FontState.custom : FontState.system
        }, set: { newValue in
          switch newValue {
          case .system:
            userPreferences.chosenFont = nil
          case .openDyslexic:
            userPreferences.chosenFont = UIFont(name: "OpenDyslexic", size: 1)
          case .hyperLegible:
            userPreferences.chosenFont = UIFont(name: "Atkinson Hyperlegible", size: 1)
          case .custom:
            isFontSelectorPresented = true
          }
        })) {
          ForEach(FontState.allCases, id: \.rawValue) { fontState in
            Text(fontState.title).tag(fontState)
          }
        }
        .navigationDestination(isPresented: $isFontSelectorPresented, destination: { FontPicker() })
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
        VStack {
          Slider(value: $userPreferences.fontSizeScale, in: 0.5 ... 1.5, step: 0.1)
          Text("settings.display.font.scaling-\(String(format: "%.1f", userPreferences.fontSizeScale))")
            .font(.scaledBody)
        }
        .alignmentGuide(.listRowSeparatorLeading) { d in
          d[.leading]
        }
        Toggle("settings.display.translate-button", isOn: $userPreferences.showTranslateButton)
      }
      .listRowBackground(theme.primaryBackgroundColor)

      if UIDevice.current.userInterfaceIdiom == .phone {
        Section("settings.display.section.phone") {
          Toggle("settings.display.show-tab-label", isOn: $userPreferences.showiPhoneTabLabel)
        }
        .listRowBackground(theme.primaryBackgroundColor)
      }

      if UIDevice.current.userInterfaceIdiom == .pad {
        Section("settings.display.section.ipad") {
          Toggle("settings.display.show-ipad-column", isOn: $userPreferences.showiPadSecondaryColumn)
        }
      }

      Section {
        Button {
          theme.followSystemColorScheme = true
          theme.selectedSet = colorScheme == .dark ? .iceCubeDark : .iceCubeLight
          theme.avatarShape = .rounded
          theme.avatarPosition = .top
          theme.statusActionsDisplay = .full
        } label: {
          Text("settings.display.restore")
        }
      }
      .listRowBackground(theme.primaryBackgroundColor)
    }
    .navigationTitle("settings.display.navigation-title")
    .scrollContentBackground(.hidden)
    .background(theme.secondaryBackgroundColor)
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
