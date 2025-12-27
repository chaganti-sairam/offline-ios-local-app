import Foundation
import SwiftUI
import Combine

/// ViewModel managing chat conversation state and interactions with the AI inference service
@MainActor
final class ChatConversationViewModel: ObservableObject {

    // MARK: - Published Properties

    /// The current chat session containing all messages
    @Published var current_chat_session: ChatSessionModel

    /// The text input from the user
    @Published var user_input_text: String = ""

    /// Indicates whether the assistant is currently generating a response
    @Published var is_assistant_responding: Bool = false

    /// The streaming response being built from tokens
    @Published var current_assistant_response: String = ""

    /// Error message to display to the user, if any
    @Published var error_message: String?

    /// Current context token count
    @Published var current_context_tokens: Int = 0

    /// Max context tokens from active model
    @Published var max_context_tokens: Int = 4096

    // MARK: - Private Properties

    /// Reference to the inference service for generating responses
    private let nexa_inference_service: NexaInferenceService

    /// Reference to storage service for persistence
    private weak var storage_service: ChatStorageService?

    /// Reference to memory service for context injection
    private weak var memory_service: MemoryStorageService?

    /// Timestamp of the last generation to enforce rate limiting
    private var last_generation_timestamp: Date?

    /// Auto-save debouncer
    private var save_work_item: DispatchWorkItem?

    /// Number of message pairs before last title update
    private var last_title_update_message_count: Int = 0

    // MARK: - Initialization

    /// Creates a new ChatConversationViewModel with the specified inference service
    init(inference_service: NexaInferenceService, storage_service: ChatStorageService? = nil) {
        self.nexa_inference_service = inference_service
        self.storage_service = storage_service
        self.current_chat_session = ChatSessionModel()
        print("[ChatVM] ViewModel initialized")
    }

    // MARK: - Session Management

    /// Loads an existing session
    func load_session(_ session: ChatSessionModel) {
        print("[ChatVM] Loading session: \(session.session_id)")
        objectWillChange.send()
        current_chat_session = session
        objectWillChange.send()
    }

    /// Creates a new session
    func start_new_session() {
        print("[ChatVM] Starting new session")

        // Save current session if it has messages
        if !current_chat_session.is_empty {
            save_current_session()
        }

        objectWillChange.send()
        current_chat_session = ChatSessionModel()
        current_assistant_response = ""
        error_message = nil
        objectWillChange.send()
    }

    /// Sets the storage service (for dependency injection after init)
    func set_storage_service(_ service: ChatStorageService) {
        self.storage_service = service
    }

    /// Sets the memory service (for dependency injection after init)
    func set_memory_service(_ service: MemoryStorageService) {
        self.memory_service = service
    }

    // MARK: - Public Methods

    /// Checks whether the user can send a message
    func can_send_message() -> Bool {
        let has_valid_input = !user_input_text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let is_not_responding = !is_assistant_responding
        let is_model_ready = nexa_inference_service.loading_state.is_ready

        return has_valid_input && is_not_responding && is_model_ready
    }

    /// Sends the current user input and generates an assistant response
    func send_user_message() async {
        print("[ChatVM] ========== SEND MESSAGE START ==========")

        guard can_send_message() else {
            print("[ChatVM] Cannot send message - conditions not met")
            return
        }

        // Rate limiting check
        if let last_timestamp = last_generation_timestamp {
            let elapsed_seconds = Date().timeIntervalSince(last_timestamp)
            if elapsed_seconds < 1.0 {
                error_message = "Please wait a moment before sending another message"
                return
            }
        }

        error_message = nil

        let trimmed_user_input = user_input_text.trimmingCharacters(in: .whitespacesAndNewlines)
        user_input_text = ""

        objectWillChange.send()
        current_chat_session.append_user_message(user_message_content: trimmed_user_input)
        objectWillChange.send()

        // Auto-save after user message
        schedule_save()

        await generate_response()
    }

    /// Regenerates the last assistant response
    func regenerate_last_response() async {
        print("[ChatVM] Regenerating last response...")

        guard !is_assistant_responding else {
            print("[ChatVM] Already generating, cannot regenerate")
            return
        }

        // Remove the last assistant message if exists
        if let last_message = current_chat_session.last_message,
           last_message.message_role == .assistant {
            objectWillChange.send()
            current_chat_session.remove_last_message()
            objectWillChange.send()
        }

        await generate_response()
    }

    /// Stops the current generation
    func stop_generation() {
        print("[ChatVM] Stopping generation...")
        nexa_inference_service.cancel_current_generation()

        // Finalize whatever we have
        if !current_assistant_response.isEmpty {
            finalize_assistant_response()
        }

        is_assistant_responding = false
    }

    /// Clears all messages from the current conversation
    func clear_conversation() {
        print("[ChatVM] Clearing conversation")

        // Delete the session from storage
        storage_service?.delete_session(session_id: current_chat_session.session_id)

        objectWillChange.send()
        current_chat_session = ChatSessionModel()
        current_assistant_response = ""
        error_message = nil
        objectWillChange.send()
    }

    /// Dismisses the current error message
    func dismiss_error_message() {
        error_message = nil
    }

    /// Exports current conversation as text
    func export_conversation() -> String {
        storage_service?.export_session_as_text(current_chat_session) ?? ""
    }

    // MARK: - Private Methods

    private func generate_response() async {
        is_assistant_responding = true
        current_assistant_response = ""

        print("[ChatVM] Starting inference...")

        // Get memory context if available
        let memory_context = memory_service?.get_formatted_memories_for_prompt() ?? ""
        if !memory_context.isEmpty {
            print("[ChatVM] Including \(memory_service?.enabled_memory_block_count ?? 0) memory blocks in context")
        }

        do {
            try await nexa_inference_service.generate_streaming_response(
                conversation_messages: current_chat_session.session_messages,
                system_prompt_context: memory_context,
                token_handler: { [weak self] token in
                    Task { @MainActor in
                        guard let self = self else { return }
                        self.current_assistant_response.append(token)
                    }
                }
            )

            print("[ChatVM] Generation complete")
            finalize_assistant_response()

        } catch {
            print("[ChatVM] Generation ERROR: \(error)")
            handle_generation_error(generation_error: error)
        }

        is_assistant_responding = false
        last_generation_timestamp = Date()
        print("[ChatVM] ========== SEND MESSAGE END ==========")
    }

    private func finalize_assistant_response() {
        let final_response = current_assistant_response.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !final_response.isEmpty else {
            print("[ChatVM] WARNING: Empty response received")
            error_message = "Assistant generated an empty response"
            current_assistant_response = ""
            return
        }

        objectWillChange.send()
        current_chat_session.append_assistant_message(assistant_message_content: final_response)
        objectWillChange.send()

        current_assistant_response = ""

        // Update context token count
        update_context_tokens()

        // Check if we should auto-generate title
        maybe_generate_session_title()

        // Auto-save after assistant response
        schedule_save()
    }

    // MARK: - Context Token Tracking

    /// Updates the current context token count
    func update_context_tokens() {
        current_context_tokens = TokenCounter.estimate_conversation_tokens(
            messages: current_chat_session.session_messages
        )
    }

    /// Updates the max context tokens based on active model
    func update_max_context_tokens(model_context_length: Int) {
        max_context_tokens = model_context_length
    }

    // MARK: - Auto-Title Generation

    /// Generates a title for the session based on conversation content
    private func maybe_generate_session_title() {
        let current_message_count = current_chat_session.message_count

        // Generate title after first 2 messages (1 user + 1 assistant)
        // Then update every 4 additional messages
        let should_generate_initial = current_message_count >= 2 && current_chat_session.session_title == nil
        let should_update = current_message_count >= 4 &&
            current_message_count - last_title_update_message_count >= 4

        guard should_generate_initial || should_update else { return }

        last_title_update_message_count = current_message_count
        generate_session_title()
    }

    /// Creates a smart title from the conversation content
    private func generate_session_title() {
        let messages = current_chat_session.session_messages

        // Get first user message for context
        guard let first_user_message = messages.first(where: { $0.message_role == .user }) else {
            return
        }

        let content = first_user_message.message_content
        let generated_title = create_smart_title(from: content)

        objectWillChange.send()
        current_chat_session.session_title = generated_title
        objectWillChange.send()

        print("[ChatVM] Auto-generated title: \(generated_title)")
    }

    /// Creates a concise title from user message content
    private func create_smart_title(from content: String) -> String {
        let cleaned_content = content
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\n", with: " ")

        // If it's a question, try to extract the key topic
        if cleaned_content.contains("?") {
            // Extract the question part
            if let question_part = cleaned_content.components(separatedBy: "?").first {
                let trimmed = question_part.trimmingCharacters(in: .whitespaces)
                if trimmed.count <= 40 {
                    return trimmed + "?"
                }
                // Find a good break point
                let words = trimmed.components(separatedBy: " ")
                var result = ""
                for word in words {
                    if result.count + word.count + 1 > 35 {
                        break
                    }
                    result += (result.isEmpty ? "" : " ") + word
                }
                return result + "...?"
            }
        }

        // For statements, extract key words
        let words = cleaned_content.components(separatedBy: " ")
        var title = ""

        for word in words {
            if title.count + word.count + 1 > 35 {
                break
            }
            title += (title.isEmpty ? "" : " ") + word
        }

        if title.count < cleaned_content.count {
            title += "..."
        }

        return title.isEmpty ? "Chat" : title
    }

    private func handle_generation_error(generation_error: Error) {
        error_message = "Failed to generate response: \(generation_error.localizedDescription)"
        current_assistant_response = ""
    }

    private func schedule_save() {
        save_work_item?.cancel()

        let work_item = DispatchWorkItem { [weak self] in
            Task { @MainActor in
                self?.save_current_session()
            }
        }

        save_work_item = work_item
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: work_item)
    }

    private func save_current_session() {
        guard !current_chat_session.is_empty else { return }
        print("[ChatVM] Auto-saving session...")
        storage_service?.save_session(current_chat_session)
    }
}
