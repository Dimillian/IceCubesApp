import Combine
import SwiftUI

public struct ThemePreviewView: View {
  private let gutterSpace: Double = 8
  @Environment(Theme.self) private var theme
  @Environment(\.dismiss) var dismiss

  public init() {}

  public var body: some View {
    ScrollView {
      ForEach(availableColorsSets) { couple in
        HStack(spacing: gutterSpace) {
          ThemeBoxView(color: couple.light)
          ThemeBoxView(color: couple.dark)
        }
      }
    }
    .padding(4)
    .frame(maxHeight: .infinity)
    .background(theme.primaryBackgroundColor)
    .navigationTitle("design.theme.navigation-title")
  }
}

struct ThemeBoxView: View {
  @Environment(Theme.self) private var theme
  private let gutterSpace = 8.0
  @State private var isSelected = false

  var color: ColorSet

  var body: some View {
    ZStack(alignment: .topTrailing) {
      Rectangle()
        .foregroundColor(.white)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .cornerRadius(4)
        .shadow(radius: 2, x: 2, y: 4)
        .accessibilityHidden(true)

      VStack(spacing: gutterSpace) {
        Text(color.name.rawValue)
          .foregroundColor(color.tintColor)
          .font(.system(size: 20))
          .fontWeight(.bold)

        Text("design.theme.toots-preview")
          .foregroundColor(color.labelColor)
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .padding()
          .background(color.primaryBackgroundColor)

        Text("#icecube, #techhub")
          .foregroundColor(color.tintColor)
        if isSelected {
          HStack {
            Spacer()
            Image(systemName: "checkmark.seal.fill")
              .resizable()
              .frame(width: 20, height: 20)
              .foregroundColor(.green)
          }
        } else {
          HStack {
            Spacer()
            Circle()
              .strokeBorder(color.tintColor, lineWidth: 1)
              .background(Circle().fill(color.primaryBackgroundColor))
              .frame(width: 20, height: 20)
          }
        }
      }
      .frame(maxWidth: .infinity)
      .padding()
      .background(color.secondaryBackgroundColor)
      .font(.system(size: 15))
      .cornerRadius(4)
    }
    .onAppear {
      isSelected = theme.selectedSet.rawValue == color.name.rawValue
    }
    .onChange(of: theme.selectedSet) { _, newValue in
      isSelected = newValue.rawValue == color.name.rawValue
    }
    .onTapGesture {
      let currentScheme = theme.selectedScheme
      if color.scheme != currentScheme {
        theme.followSystemColorScheme = false
      }
      theme.applySet(set: color.name)
    }
  }
}
