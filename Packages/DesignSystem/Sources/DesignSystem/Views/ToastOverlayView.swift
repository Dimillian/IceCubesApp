import Env
import SwiftUI

public struct ToastOverlayView: View {
  @Environment(ToastCenter.self) private var toastCenter
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  public init() {}

  public var body: some View {
    ZStack(alignment: .top) {
      if let toast = toastCenter.toast {
        toastContent(toast)
          .transition(.move(edge: .top).combined(with: .opacity))
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    .animation(
      reduceMotion ? .easeInOut(duration: 0.2) : .bouncy(duration: 0.4),
      value: toastCenter.toast)
    .allowsHitTesting(toastCenter.toast != nil)
  }

  @ViewBuilder
  private func toastContent(_ toast: ToastCenter.Toast) -> some View {
    if toast.action != nil {
      Button {
        toast.action?.handler()
        toastCenter.dismiss(id: toast.id)
      } label: {
        ToastView(toast: toast)
          .padding(.horizontal, .layoutPadding)
          .padding(.top, 12)
      }
      .buttonStyle(.plain)
    } else {
      ToastView(toast: toast)
        .padding(.horizontal, .layoutPadding)
        .padding(.top, 12)
        .contentShape(Rectangle())
        .onTapGesture {
          toastCenter.dismiss(id: toast.id)
        }
    }
  }
}

private struct ToastView: View {
  let toast: ToastCenter.Toast

  var body: some View {
    if #available(iOS 26.0, *) {
      content
        .padding(12)
        .glassEffect(
          .regular.tint(toast.tint.opacity(0.05)).interactive(),
          in: .rect(cornerRadius: 18)
        )
    } else {
      content
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
        .overlay(
          RoundedRectangle(cornerRadius: 18)
            .strokeBorder(toast.tint.opacity(0.05), lineWidth: 1)
        )
    }
  }

  private var content: some View {
    HStack(alignment: .top, spacing: 12) {
      if let systemImage = toast.systemImage {
        Image(systemName: systemImage)
          .font(.title3)
          .foregroundStyle(toast.tint)
      }

      VStack(alignment: .leading, spacing: 6) {
        Text(toast.title)
          .font(.headline)
          .foregroundStyle(.primary)
          .lineLimit(2)

        if let message = toast.message {
          Text(message)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .lineLimit(3)
        }

        if toast.kind == .progress {
          if let progress = toast.progress {
            ProgressView(value: progress, total: 100.0)
              .tint(toast.tint)
          } else {
            ProgressView()
              .tint(toast.tint)
          }
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
  }

}
