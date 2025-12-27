import Foundation

/// Represents a chat session containing multiple messages
struct ChatSessionModel: Identifiable, Codable, Equatable {
    let session_id: UUID
    var session_title: String?
    var session_messages: [ChatMessageModel]
    var session_created_timestamp: Date
    var session_last_updated_timestamp: Date

    var id: UUID { session_id }

    init(
        session_id: UUID = UUID(),
        session_title: String? = nil,
        session_messages: [ChatMessageModel] = [],
        session_created_timestamp: Date = Date()
    ) {
        self.session_id = session_id
        self.session_title = session_title
        self.session_messages = session_messages
        self.session_created_timestamp = session_created_timestamp
        self.session_last_updated_timestamp = session_created_timestamp
    }

    /// Returns display title (custom title or first message preview)
    var display_title: String {
        if let title = session_title, !title.isEmpty {
            return title
        }

        if let first_user_message = session_messages.first(where: { $0.message_role == .user }) {
            let content = first_user_message.message_content
            if content.count > 35 {
                return String(content.prefix(35)) + "..."
            }
            return content
        }

        return "New Chat"
    }

    /// Appends a user message to the session
    mutating func append_user_message(user_message_content: String) {
        let new_message = ChatMessageModel.create_user_message(content: user_message_content)
        session_messages.append(new_message)
        session_last_updated_timestamp = Date()
    }

    /// Appends an assistant message to the session
    mutating func append_assistant_message(assistant_message_content: String) {
        let new_message = ChatMessageModel.create_assistant_message(content: assistant_message_content)
        session_messages.append(new_message)
        session_last_updated_timestamp = Date()
    }

    /// Appends a system message to the session
    mutating func append_system_message(system_message_content: String) {
        let new_message = ChatMessageModel.create_system_message(content: system_message_content)
        session_messages.append(new_message)
        session_last_updated_timestamp = Date()
    }

    /// Removes the last message (useful for regenerate)
    mutating func remove_last_message() {
        if !session_messages.isEmpty {
            session_messages.removeLast()
            session_last_updated_timestamp = Date()
        }
    }

    /// Clears all messages from the session
    mutating func clear_all_messages() {
        session_messages.removeAll()
        session_last_updated_timestamp = Date()
    }

    /// Returns the total number of messages in the session
    var message_count: Int {
        session_messages.count
    }

    /// Returns true if the session has no messages
    var is_empty: Bool {
        session_messages.isEmpty
    }

    /// Returns the last message in the session, if any
    var last_message: ChatMessageModel? {
        session_messages.last
    }

    /// Trims old messages to stay within context limits
    /// Keeps the most recent messages up to the specified count
    mutating func trim_to_recent_messages(max_message_count: Int) {
        guard session_messages.count > max_message_count else { return }
        let messages_to_keep = session_messages.suffix(max_message_count)
        session_messages = Array(messages_to_keep)
        session_last_updated_timestamp = Date()
    }

    /// Formats all messages for the LLM prompt
    func format_conversation_for_prompt() -> String {
        session_messages
            .map { $0.format_for_llm_prompt() }
            .joined(separator: "\n")
    }

    static func == (lhs: ChatSessionModel, rhs: ChatSessionModel) -> Bool {
        lhs.session_id == rhs.session_id
    }
}
