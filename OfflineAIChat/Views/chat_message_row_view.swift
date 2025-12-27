import SwiftUI
import UIKit

struct ChatMessageRowView: View {
    let message: ChatMessageModel
    var on_regenerate: (() -> Void)? = nil

    @State private var show_copied_feedback = false

    private var is_user_message: Bool {
        message.message_role == .user
    }

    private var bubble_background_color: Color {
        switch message.message_role {
        case .user:
            return Color.blue
        case .assistant:
            return Color(.systemGray5)
        case .system:
            return Color(.systemGray6)
        }
    }

    private var text_foreground_color: Color {
        switch message.message_role {
        case .user:
            return .white
        case .assistant, .system:
            return .primary
        }
    }

    private var formatted_timestamp: String {
        let date_formatter = DateFormatter()
        date_formatter.timeStyle = .short
        date_formatter.dateStyle = .none
        return date_formatter.string(from: message.message_created_timestamp)
    }

    private var word_count: Int {
        message.message_content.split(separator: " ").count
    }

    var body: some View {
        HStack {
            if is_user_message {
                Spacer(minLength: 60)
            }

            VStack(alignment: is_user_message ? .trailing : .leading, spacing: 4) {
                message_bubble_view
                    .contextMenu {
                        context_menu_content
                    }

                HStack(spacing: 8) {
                    timestamp_label_view

                    if !is_user_message && word_count > 10 {
                        Text("•")
                            .font(.caption2)
                            .foregroundColor(.secondary)

                        Text("\(word_count) words")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }

            if !is_user_message {
                Spacer(minLength: 60)
            }
        }
        .overlay(alignment: is_user_message ? .trailing : .leading) {
            if show_copied_feedback {
                copied_feedback_view
            }
        }
    }

    // MARK: - Message Bubble

    private var message_bubble_view: some View {
        Text(message.message_content)
            .foregroundColor(text_foreground_color)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(bubble_background_color)
            .cornerRadius(16)
            .textSelection(.enabled)
    }

    // MARK: - Context Menu

    @ViewBuilder
    private var context_menu_content: some View {
        Button {
            copy_to_clipboard()
        } label: {
            Label("Copy", systemImage: "doc.on.doc")
        }

        Button {
            share_message()
        } label: {
            Label("Share", systemImage: "square.and.arrow.up")
        }

        if !is_user_message, let regenerate = on_regenerate {
            Divider()

            Button {
                regenerate()
            } label: {
                Label("Regenerate", systemImage: "arrow.clockwise")
            }
        }

        Divider()

        // Info section
        Text("Sent \(formatted_timestamp)")
        if word_count > 0 {
            Text("\(word_count) words • \(message.message_content.count) characters")
        }
    }

    // MARK: - Timestamp Label

    private var timestamp_label_view: some View {
        Text(formatted_timestamp)
            .font(.caption2)
            .foregroundColor(.secondary)
            .padding(.horizontal, 8)
    }

    // MARK: - Copied Feedback

    private var copied_feedback_view: some View {
        Text("Copied!")
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.black.opacity(0.75))
            .cornerRadius(8)
            .offset(y: -50)
            .transition(.scale.combined(with: .opacity))
    }

    // MARK: - Actions

    private func copy_to_clipboard() {
        UIPasteboard.general.string = message.message_content

        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        // Show copied feedback
        withAnimation(.spring(response: 0.3)) {
            show_copied_feedback = true
        }

        // Hide after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeOut) {
                show_copied_feedback = false
            }
        }
    }

    private func share_message() {
        let text = message.message_content

        // Get the key window scene
        guard let window_scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root_controller = window_scene.windows.first?.rootViewController else {
            return
        }

        let activity_controller = UIActivityViewController(
            activityItems: [text],
            applicationActivities: nil
        )

        // For iPad
        if let popover = activity_controller.popoverPresentationController {
            popover.sourceView = root_controller.view
            popover.sourceRect = CGRect(x: root_controller.view.bounds.midX, y: root_controller.view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }

        root_controller.present(activity_controller, animated: true)
    }
}

// MARK: - Preview

#Preview("User Message") {
    VStack(spacing: 16) {
        ChatMessageRowView(
            message: ChatMessageModel(
                message_role: .user,
                message_content: "Hello! How can you help me today?"
            )
        )

        ChatMessageRowView(
            message: ChatMessageModel(
                message_role: .assistant,
                message_content: "Hello! I'm an AI assistant running locally on your device. I can help you with various tasks like answering questions, having conversations, or providing information. What would you like to know?"
            ),
            on_regenerate: { print("Regenerate tapped") }
        )

        ChatMessageRowView(
            message: ChatMessageModel(
                message_role: .user,
                message_content: "That's great! Can you tell me about offline AI capabilities?"
            )
        )
    }
    .padding()
}
