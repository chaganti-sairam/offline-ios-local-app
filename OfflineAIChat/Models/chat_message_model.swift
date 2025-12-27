import Foundation

/// Represents a single message in a chat conversation
struct ChatMessageModel: Identifiable, Codable, Equatable {
    let message_id: UUID
    let message_role: MessageRole
    let message_content: String
    let message_created_timestamp: Date

    enum MessageRole: String, Codable {
        case user
        case assistant
        case system
    }

    init(
        message_id: UUID = UUID(),
        message_role: MessageRole,
        message_content: String,
        message_created_timestamp: Date = Date()
    ) {
        self.message_id = message_id
        self.message_role = message_role
        self.message_content = message_content
        self.message_created_timestamp = message_created_timestamp
    }

    var id: UUID { message_id }

    /// Formats the message for the LLM chat template
    func format_for_llm_prompt() -> String {
        let role_prefix: String
        switch message_role {
        case .user:
            role_prefix = "User"
        case .assistant:
            role_prefix = "Assistant"
        case .system:
            role_prefix = "System"
        }
        return "\(role_prefix): \(message_content)"
    }
}

// MARK: - Message Creation Helpers

extension ChatMessageModel {

    /// Creates a user message with the given content
    static func create_user_message(content: String) -> ChatMessageModel {
        ChatMessageModel(
            message_role: .user,
            message_content: content
        )
    }

    /// Creates an assistant message with the given content
    static func create_assistant_message(content: String) -> ChatMessageModel {
        ChatMessageModel(
            message_role: .assistant,
            message_content: content
        )
    }

    /// Creates a system message with the given content
    static func create_system_message(content: String) -> ChatMessageModel {
        ChatMessageModel(
            message_role: .system,
            message_content: content
        )
    }
}
