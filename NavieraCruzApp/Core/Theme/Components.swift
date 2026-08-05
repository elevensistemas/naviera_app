import SwiftUI

struct CustomTextField: View {
    var placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    
    var body: some View {
        Group {
            if isSecure {
                SecureField(placeholder, text: $text)
            } else {
                TextField(placeholder, text: $text)
            }
        }
        .padding()
        .background(ColorTheme.secondaryBackground)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
}

struct PrimaryButton: View {
    var title: String
    var isLoading: Bool = false
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Spacer()
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text(title)
                        .font(Typography.headline())
                }
                Spacer()
            }
            .padding()
            .background(ColorTheme.fallbackPrimary)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .disabled(isLoading)
    }
}
