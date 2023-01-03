import SwiftUI
import Combine

public struct ThemePreviewView: View {
  private let gutterSpace: Double = 8
  @EnvironmentObject private var theme: Theme
  @Environment(\.dismiss) var dismiss
  
  public init() {}
  
  public var body: some View {
    VStack {
      HStack {
        Text("Select Theme")
          .font(.title3)
          .fontWeight(.medium)
          .foregroundColor(theme.tintColor)
        Spacer()
        Button {
          dismiss()
        } label: {
          Image(systemName: "xmark.circle.fill")
            .resizable()
            .frame(width: 24, height: 24)
            .foregroundColor(theme.tintColor)
        }
      }
      .padding()
      ScrollView {
        HStack (spacing: gutterSpace) {
          ThemeBoxView(color: IceCubeDark())
          ThemeBoxView(color: IceCubeLight())
        }
        HStack (spacing: gutterSpace) {
          ThemeBoxView(color: DesertDark())
          ThemeBoxView(color: DesertLight())
        }
        HStack (spacing: gutterSpace) {
          ThemeBoxView(color: NemesisDark())
          ThemeBoxView(color: NemesisLight())
        }
      }
      .padding([.horizontal], 4)
      .frame(maxHeight: .infinity)
    }
    .background(theme.primaryBackgroundColor)
  }
}

struct ThemeBoxView: View {
  
  @EnvironmentObject var theme: Theme
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
      
      VStack (spacing: gutterSpace) {
        Text(color.name.rawValue)
          .foregroundColor(color.tintColor)
          .font(.system(size: 20))
          .fontWeight(.bold)
        
        Text("Toots preview")
          .foregroundColor(color.labelColor)
          .frame(maxWidth: .infinity)
          .padding()
          .background(color.primaryBackgroundColor)
        
        Text("#icecube, #techhub")
          .foregroundColor(color.tintColor)
        if isSelected {
          Image(systemName: "checkmark.circle.fill")
            .resizable()
            .frame(width: 20, height: 20)
            .foregroundColor(.green)
        } else {
          Circle()
            .strokeBorder(color.tintColor, lineWidth: 1)
            .background(Circle().fill(color.primaryBackgroundColor))
            .frame(width: 20, height: 20)
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
    .onChange(of: theme.selectedSet) { newValue in
      isSelected = newValue.rawValue == color.name.rawValue
    }
    .onTapGesture {
      theme.selectedSet = color.name
    }
  }
}

