import SwiftUI

struct ChatInputFieldView: View {
    @Binding var user_input_text: String
    let is_assistant_responding: Bool
    let on_send: () -> Void

    @FocusState private var is_text_field_focused: Bool

    private var is_send_button_disabled: Bool {
        user_input_text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || is_assistant_responding
    }

    private var send_button_icon_name: String {
        "arrow.up.circle.fill"
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 12) {
            text_input_field_view

            send_or_loading_button_view
        }
    }

    // MARK: - Text Input Field

    private var text_input_field_view: some View {
        TextField("Type a message...", text: $user_input_text, axis: .vertical)
            .lineLimit(1...5)
            .textFieldStyle(.roundedBorder)
            .focused($is_text_field_focused)
            .disabled(is_assistant_responding)
            .onSubmit {
                if !is_send_button_disabled {
                    on_send()
                }
            }
    }

    // MARK: - Send or Loading Button

    private var send_or_loading_button_view: some View {
        Group {
            if is_assistant_responding {
                ProgressView()
                    .frame(width: 32, height: 32)
            } else {
                Button(action: {
                    on_send()
                    is_text_field_focused = false
                }) {
                    Image(systemName: send_button_icon_name)
                        .font(.system(size: 28))
                        .foregroundColor(is_send_button_disabled ? .gray : .blue)
                }
                .disabled(is_send_button_disabled)
            }
        }
        .frame(width: 32, height: 32)
    }
}

// MARK: - Preview

#Preview("Empty Input") {
    VStack {
        Spacer()

        ChatInputFieldView(
            user_input_text: .constant(""),
            is_assistant_responding: false,
            on_send: {}
        )
        .padding()
    }
}

#Preview("With Text") {
    VStack {
        Spacer()

        ChatInputFieldView(
            user_input_text: .constant("Hello, this is a test message that spans multiple lines to show how the text field expands."),
            is_assistant_responding: false,
            on_send: {}
        )
        .padding()
    }
}

#Preview("Loading State") {
    VStack {
        Spacer()

        ChatInputFieldView(
            user_input_text: .constant("Previous message"),
            is_assistant_responding: true,
            on_send: {}
        )
        .padding()
    }
}
