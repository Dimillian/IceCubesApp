import SwiftUI
import UIKit

// ref: https://stackoverflow.com/questions/74238414/is-there-an-easy-way-to-pinch-to-zoom-and-drag-any-view-in-swiftui

private let maxAllowedScale = 4.0

@MainActor
struct MediaUIZoomableContainer<Content: View>: View {
  let content: Content
  @State private var currentScale: CGFloat = 1.0
  @State private var tapLocation: CGPoint = .zero

  init(@ViewBuilder content: () -> Content) {
    self.content = content()
  }

  func doubleTapAction(location: CGPoint) {
    tapLocation = location
    currentScale = currentScale == 1.0 ? maxAllowedScale : 1.0
  }

  var body: some View {
    ZoomableScrollView(scale: $currentScale, tapLocation: $tapLocation) {
      content
    }
    .onTapGesture(count: 2, perform: doubleTapAction)
  }

  fileprivate struct ZoomableScrollView<ScollContent: View>: UIViewRepresentable {
    private var content: ScollContent
    @Binding private var currentScale: CGFloat
    @Binding private var tapLocation: CGPoint

    init(scale: Binding<CGFloat>, tapLocation: Binding<CGPoint>, @ViewBuilder content: () -> ScollContent) {
      _currentScale = scale
      _tapLocation = tapLocation
      self.content = content()
    }

    func makeUIView(context: Context) -> UIScrollView {
      let scrollView = UIScrollView()
      scrollView.backgroundColor = .clear
      scrollView.delegate = context.coordinator
      scrollView.maximumZoomScale = maxAllowedScale
      scrollView.minimumZoomScale = 1
      scrollView.bouncesZoom = true
      scrollView.showsHorizontalScrollIndicator = false
      scrollView.showsVerticalScrollIndicator = false
      scrollView.clipsToBounds = false
      scrollView.backgroundColor = .clear

      let hostedView = context.coordinator.hostingController.view!
      hostedView.translatesAutoresizingMaskIntoConstraints = true
      hostedView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
      hostedView.frame = scrollView.bounds
      hostedView.backgroundColor = .clear
      scrollView.addSubview(hostedView)

      return scrollView
    }

    func makeCoordinator() -> Coordinator {
      Coordinator(hostingController: UIHostingController(rootView: content), scale: $currentScale)
    }

    func updateUIView(_ uiView: UIScrollView, context: Context) {
      context.coordinator.hostingController.rootView = content

      if uiView.zoomScale > uiView.minimumZoomScale { // Scale out
        uiView.setZoomScale(currentScale, animated: true)
      } else if tapLocation != .zero { // Scale in to a specific point
        uiView.zoom(to: zoomRect(for: uiView, scale: uiView.maximumZoomScale, center: tapLocation), animated: true)
        DispatchQueue.main.async { tapLocation = .zero }
      }
    }

    @MainActor func zoomRect(for scrollView: UIScrollView, scale: CGFloat, center: CGPoint) -> CGRect {
      let scrollViewSize = scrollView.bounds.size

      let width = scrollViewSize.width / scale
      let height = scrollViewSize.height / scale
      let x = center.x - (width / 2.0)
      let y = center.y - (height / 2.0)

      return CGRect(x: x, y: y, width: width, height: height)
    }

    class Coordinator: NSObject, UIScrollViewDelegate {
      var hostingController: UIHostingController<ScollContent>
      @Binding var currentScale: CGFloat

      init(hostingController: UIHostingController<ScollContent>, scale: Binding<CGFloat>) {
        self.hostingController = hostingController
        _currentScale = scale
      }

      func viewForZooming(in _: UIScrollView) -> UIView? {
        hostingController.view
      }

      func scrollViewDidEndZooming(_: UIScrollView, with _: UIView?, atScale scale: CGFloat) {
        currentScale = scale
      }
    }
  }
}
