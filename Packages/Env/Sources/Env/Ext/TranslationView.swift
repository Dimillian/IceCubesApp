import SwiftUI

#if canImport(_Translation_SwiftUI)
  import Translation

  extension View {
    public func addTranslateView(isPresented: Binding<Bool>, text: String) -> some View {
      #if targetEnvironment(macCatalyst) || os(visionOS)
        return self
      #else
        if #available(iOS 17.4, *) {
          return self.translationPresentation(isPresented: isPresented, text: text)
        } else {
          return self
        }
      #endif
    }
  }
#endif
