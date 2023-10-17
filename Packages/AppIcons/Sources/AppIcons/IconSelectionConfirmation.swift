import SwiftUI

struct IconSelectionConfirmation: View {
    @Environment(\.dismiss) private var dismissAction
    var icon: AppIcon
    var confirmAction: (AppIcon) -> Void

    private let containerCornerRadius: CGFloat = 36.0

   @ViewBuilder
    var content: some View {
        VStack {
            IconView(icon)
                .clipShape(ContainerRelativeShape())

            Spacer()

            Button {
                confirmAction(icon)
                dismissAction()
            } label: {
                Text("Set App Icon")
                    .bold()
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .clipShape(ContainerRelativeShape())

            Button(role: .cancel) {
                dismissAction()
            } label: {
                Text("Cancel")
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .clipShape(ContainerRelativeShape())

        }
        .padding()
    }

    var body: some View {
        GeometryReader { g in
            content
                .containerShape(.rect(cornerRadius: containerCornerRadius))
                .presentationDetents([.fraction(0.75)])
                .presentationCornerRadius(containerCornerRadius)
                .presentationBackground(.regularMaterial)
        }
    }
}

#Preview {
    Color.purple.ignoresSafeArea().sheet(item: .constant(AppIcon.alt1)) { appIcon in
        IconSelectionConfirmation(icon: appIcon) { selectedAppIcon in
            print(selectedAppIcon.appIconName)
        }
    }
}
