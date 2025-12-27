import Foundation

/// Service for persisting chat sessions to disk
@MainActor
final class ChatStorageService: ObservableObject {

    // MARK: - Published Properties

    @Published var saved_sessions: [ChatSessionModel] = []

    // MARK: - Private Properties

    private let file_manager = FileManager.default
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private var storage_directory_url: URL {
        let documents = file_manager.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documents.appendingPathComponent("ChatSessions", isDirectory: true)
    }

    // MARK: - Initialization

    init() {
        print("[ChatStorage] Initializing storage service...")
        create_storage_directory_if_needed()
        load_all_sessions()
    }

    // MARK: - Public Methods

    /// Saves a chat session to disk
    func save_session(_ session: ChatSessionModel) {
        let file_url = session_file_url(for: session.session_id)

        do {
            let data = try encoder.encode(session)
            try data.write(to: file_url)
            print("[ChatStorage] Saved session: \(session.session_id)")

            // Update in-memory list
            if let index = saved_sessions.firstIndex(where: { $0.session_id == session.session_id }) {
                saved_sessions[index] = session
            } else {
                saved_sessions.insert(session, at: 0)
            }

            // Sort by last updated
            sort_sessions_by_recency()

        } catch {
            print("[ChatStorage] Error saving session: \(error)")
        }
    }

    /// Loads a specific session from disk
    func load_session(session_id: UUID) -> ChatSessionModel? {
        let file_url = session_file_url(for: session_id)

        guard file_manager.fileExists(atPath: file_url.path) else {
            print("[ChatStorage] Session file not found: \(session_id)")
            return nil
        }

        do {
            let data = try Data(contentsOf: file_url)
            let session = try decoder.decode(ChatSessionModel.self, from: data)
            print("[ChatStorage] Loaded session: \(session_id)")
            return session
        } catch {
            print("[ChatStorage] Error loading session: \(error)")
            return nil
        }
    }

    /// Deletes a session from disk
    func delete_session(session_id: UUID) {
        let file_url = session_file_url(for: session_id)

        do {
            if file_manager.fileExists(atPath: file_url.path) {
                try file_manager.removeItem(at: file_url)
                print("[ChatStorage] Deleted session: \(session_id)")
            }

            // Remove from in-memory list
            saved_sessions.removeAll { $0.session_id == session_id }

        } catch {
            print("[ChatStorage] Error deleting session: \(error)")
        }
    }

    /// Exports a session as plain text
    func export_session_as_text(_ session: ChatSessionModel) -> String {
        var text = "Chat Export - \(formatted_date(session.session_created_timestamp))\n"
        text += String(repeating: "=", count: 50) + "\n\n"

        for message in session.session_messages {
            let role_label: String
            switch message.message_role {
            case .user:
                role_label = "You"
            case .assistant:
                role_label = "AI"
            case .system:
                role_label = "System"
            }

            let timestamp = formatted_time(message.message_created_timestamp)
            text += "[\(timestamp)] \(role_label):\n"
            text += message.message_content + "\n\n"
        }

        text += String(repeating: "=", count: 50) + "\n"
        text += "Exported from Offline AI Chat\n"

        return text
    }

    /// Returns a preview/title for a session
    func session_preview_title(_ session: ChatSessionModel) -> String {
        if let first_user_message = session.session_messages.first(where: { $0.message_role == .user }) {
            let content = first_user_message.message_content
            if content.count > 40 {
                return String(content.prefix(40)) + "..."
            }
            return content
        }
        return "New Chat"
    }

    /// Returns formatted date for session
    func session_formatted_date(_ session: ChatSessionModel) -> String {
        let calendar = Calendar.current
        let now = Date()

        if calendar.isDateInToday(session.session_last_updated_timestamp) {
            return "Today, " + formatted_time(session.session_last_updated_timestamp)
        } else if calendar.isDateInYesterday(session.session_last_updated_timestamp) {
            return "Yesterday"
        } else {
            return formatted_date(session.session_last_updated_timestamp)
        }
    }

    // MARK: - Private Methods

    private func create_storage_directory_if_needed() {
        if !file_manager.fileExists(atPath: storage_directory_url.path) {
            do {
                try file_manager.createDirectory(at: storage_directory_url, withIntermediateDirectories: true)
                print("[ChatStorage] Created storage directory")
            } catch {
                print("[ChatStorage] Error creating storage directory: \(error)")
            }
        }
    }

    private func load_all_sessions() {
        do {
            let file_urls = try file_manager.contentsOfDirectory(
                at: storage_directory_url,
                includingPropertiesForKeys: nil
            ).filter { $0.pathExtension == "json" }

            var sessions: [ChatSessionModel] = []

            for file_url in file_urls {
                if let data = try? Data(contentsOf: file_url),
                   let session = try? decoder.decode(ChatSessionModel.self, from: data) {
                    sessions.append(session)
                }
            }

            saved_sessions = sessions
            sort_sessions_by_recency()
            print("[ChatStorage] Loaded \(saved_sessions.count) sessions")

        } catch {
            print("[ChatStorage] Error loading sessions: \(error)")
        }
    }

    private func session_file_url(for session_id: UUID) -> URL {
        storage_directory_url.appendingPathComponent("\(session_id.uuidString).json")
    }

    private func sort_sessions_by_recency() {
        saved_sessions.sort { $0.session_last_updated_timestamp > $1.session_last_updated_timestamp }
    }

    private func formatted_date(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    private func formatted_time(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
