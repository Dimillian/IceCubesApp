import DesignSystem
import SwiftUI
import UIKit

extension ButtonStyle where Self == StatusActionButtonStyle {
  static func statusAction(isOn: Bool = false, tintColor: Color? = nil) -> Self {
    StatusActionButtonStyle(isOn: isOn, tintColor: tintColor)
  }
}

/// A toggle button that slightly scales and sends particle on activation,
/// changing its foreground color to `tintColor` when toggled on
struct StatusActionButtonStyle: ButtonStyle {
  var isOn: Bool
  var tintColor: Color?

  @State var sparklesCounter: Float = 0

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .foregroundColor(isOn ? tintColor : Color(UIColor.secondaryLabel))
      .animation(nil, value: isOn)
      .brightness(brightness(configuration: configuration))
      .animation(configuration.isPressed ? nil : .default, value: isOn)
      .scaleEffect(configuration.isPressed && !isOn ? 0.8 : 1.0)
      .background {
        if let tint = tintColor {
          SparklesView(counter: sparklesCounter, tint: tint, size: 5, velocity: 30)
        }
      }
      .onChange(of: configuration.isPressed) { _, newValue in
        guard tintColor != nil, !newValue, !isOn else { return }

        withAnimation(.spring(response: 1, dampingFraction: 1)) {
          sparklesCounter += 1
        }
      }
  }

  func brightness(configuration: Configuration) -> Double {
    switch (configuration.isPressed, isOn) {
    case (true, true): 0.6
    case (true, false): 0.2
    default: 0
    }
  }

  struct SparklesView: View, Animatable {
    var counter: Float
    var tint: Color
    var size: CGFloat
    var velocity: CGFloat

    var animatableData: Float {
      get { counter }
      set { counter = newValue }
    }

    struct Cell: Identifiable {
      var id: Int
      var angle: CGFloat
      var velocity: CGFloat
      var scale: CGFloat
      var alpha: CGFloat
    }

    @State var cells: [Cell] = []

    var progress: CGFloat {
      CGFloat(counter - counter.rounded(.down))
    }

    public var body: some View {
      if progress > 0.0 {
        ZStack(alignment: .center) {
          ForEach(cells) { cell in
            Circle()
              .frame(width: size, height: size)
              .foregroundColor(tint)
              .opacity(cell.alpha - (progress * cell.alpha) / 3)
              .scaleEffect(cell.scale - progress * cell.scale)
              .offset(
                x: cos(cell.angle) * progress * cell.velocity * velocity,
                y: sin(cell.angle) * progress * cell.velocity * velocity
              )
          }
        }
        .onAppear {
          cells = Self.generateCells()
        }
        .onChange(of: counter) { oldValue, newValue in
          if floor(oldValue) != floor(newValue) {
            cells = Self.generateCells()
          }
        }
      }
    }

    static func generateCells() -> [Cell] {
      let cellCount = 16
      let velocityRange = 0.6 ... 1.0
      let scaleRange = 0.5 ... 1.0
      let alphaRange = 0.6 ... 1.0

      let spacing = 2 * .pi / (1.618 + Double(arc4random() % 200) / 10000)
      let initialSpacing = deg2rad(Double(arc4random() % 360))
      return (0 ..< cellCount).map { index in
        Cell(
          id: index,
          angle: initialSpacing + spacing * Double(index),
          velocity: random(within: velocityRange),
          scale: random(within: scaleRange),
          alpha: random(within: alphaRange)
        )
      }
    }

    static func random(within range: ClosedRange<Double>) -> Double {
      Double(arc4random()) / 0xFFFF_FFFF * (range.upperBound - range.lowerBound) + range.lowerBound
    }

    static func deg2rad(_ number: Double) -> Double {
      number * .pi / 180
    }
  }
}
