import Combine
import SwiftUI

public struct TabBarIconPreviewView: View {
  @EnvironmentObject private var theme: Theme
  @Environment(\.dismiss) var dismiss

  public init() {}
  
  public var body: some View {
      ScrollView {
        ForEach(availableTabBarIconSets, id: \.id) { iconSet in
          TabBarBoxView(iconSet: iconSet)
        }
      }
      .padding(4)
      .frame(maxHeight: .infinity)
      .background(theme.primaryBackgroundColor)
      .navigationTitle("design.theme.navigation-title")
  }
}

struct TabBarBoxView: View {
  private let gutterSpace: Double = 8
  @EnvironmentObject private var theme: Theme
  @State private var isSelected = false
  
  var iconSet: TabBarIconSet
  
  var body: some View {
    VStack {
      HStack(spacing: gutterSpace) {
        HStack(spacing: gutterSpace) {
          Spacer()
          IconView(
            iconName: iconSet.tabIcon["timeline"]!,
            scale: 1.25,
            color: .blue
          )
          IconView(
            iconName: iconSet.tabIcon["notifications"]!
          )
          IconView(
            iconName: iconSet.tabIcon["explore"]!
          )
          IconView(
            iconName: iconSet.tabIcon["messages"]!
          )
          IconView(
            iconName: iconSet.tabIcon["profile"]!
          )
        }
        .frame(width: nil, height: 60)
        .background(.thinMaterial)
        .cornerRadius(20)
        .padding()
        
        if (isSelected) {
          Image(systemName: "checkmark.seal.fill")
            .resizable()
            .frame(width: 30, height: 30)
            .foregroundColor(.green)
          
          Spacer()
        }
      }
      .onAppear {
        isSelected = theme.selectedTabBarIconSet.rawValue == iconSet.id.rawValue
      }
      .onChange(of: theme.selectedTabBarIconSet) { newValue in
        isSelected = newValue.rawValue == iconSet.id.rawValue
      }
      .onTapGesture {
        theme.selectedTabBarIconSet = iconSet.id
      }
      
      Text(iconSet.name.rawValue)
        .font(.title3)
        .bold()
      
      Spacer()
    }
    
  }
}

struct IconView: View {
  var iconName: String
  var scale: Double = 1.0
  var color: Color = .gray
  
  var body: some View {
    Image(systemName: iconName)
      .scaleEffect(scale)
      .foregroundColor(color)
      .font(.system(size: 20))
    Spacer()
  }
}
