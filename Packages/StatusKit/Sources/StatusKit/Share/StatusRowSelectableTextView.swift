import DesignSystem
import SwiftUI

struct StatusRowSelectableTextView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(Theme.self) private var theme

  let content: AttributedString

  var body: some View {
    NavigationStack {
      SelectableText(content: content)
        .padding()
        .toolbar {
          ToolbarItem(placement: .navigationBarTrailing) {
            Button {
              dismiss()
            } label: {
              Text("action.done").bold()
            }
          }
        }
        .navigationTitle("status.action.select-text")
        .navigationBarTitleDisplayMode(.inline)
    }
    .presentationDetents([.medium, .large])
  }
}

private struct SelectableText: UIViewRepresentable {
  let content: AttributedString

  func makeUIView(context _: Context) -> UITextView {
    let attributedText = NSMutableAttributedString(content)
    attributedText.addAttribute(
      .font,
      value: Font.scaledBodyFont,
      range: NSRange(location: 0, length: content.characters.count)
    )

    let textView = UITextView()
    textView.translatesAutoresizingMaskIntoConstraints = false
    textView.isEditable = false
    textView.isScrollEnabled = true
    textView.attributedText = attributedText
    textView.textColor = UIColor(Color.label)
    textView.select(textView)
    textView.selectedRange = .init(location: 0, length: attributedText.string.utf8.count)
    textView.backgroundColor = .clear
    return textView
  }

  func updateUIView(_: UITextView, context _: Context) {}
  func makeCoordinator() {}
}
