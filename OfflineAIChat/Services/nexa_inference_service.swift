import Foundation
import SwiftUI
import NexaSdk

/// Errors that can occur during inference operations
enum NexaInferenceError: Error, LocalizedError {
    case model_not_found
    case model_initialization_failed(String)
    case model_not_ready
    case loading_cancelled
    case inference_failed(String)
    case generation_already_in_progress
    case no_model_selected

    var errorDescription: String? {
        switch self {
        case .model_not_found:
            return "AI model not found. Please download a model first."
        case .model_initialization_failed(let reason):
            return "Failed to initialize AI model: \(reason)"
        case .model_not_ready:
            return "The AI model is not ready yet."
        case .loading_cancelled:
            return "Model loading was cancelled."
        case .inference_failed(let reason):
            return "Inference failed: \(reason)"
        case .generation_already_in_progress:
            return "A response is already being generated."
        case .no_model_selected:
            return "No model selected. Please select a model in settings."
        }
    }
}

/// Model loading state
enum ModelLoadingState: Equatable {
    case uninitialized
    case loading
    case ready
    case error(String)

    var is_loading: Bool {
        if case .loading = self { return true }
        return false
    }

    var is_ready: Bool {
        if case .ready = self { return true }
        return false
    }
}

/// Service responsible for running local AI inference using Nexa SDK
@MainActor
final class NexaInferenceService: ObservableObject {

    // MARK: - Published Properties

    @Published var loading_state: ModelLoadingState = .uninitialized
    @Published var is_currently_generating: Bool = false
    @Published var loaded_model: AvailableModel?

    // MARK: - Private Properties

    private var llm_instance: LLM?
    private var should_cancel_generation: Bool = false

    // MARK: - Initialization

    init() {
        print("[NexaInference] ========== SERVICE INITIALIZED ==========")
    }

    // MARK: - Public Methods

    /// Loads the specified model into memory
    func load_model(_ model: AvailableModel) async throws {
        print("[NexaInference] ========== LOAD MODEL START ==========")
        print("[NexaInference] Model: \(model.display_name)")
        print("[NexaInference] File path: \(model.local_file_url.path)")
        print("[NexaInference] File exists: \(model.is_downloaded)")

        guard model.is_downloaded else {
            print("[NexaInference] ERROR: Model file not found!")
            throw NexaInferenceError.model_not_found
        }

        // Don't reload if already loaded
        if loaded_model == model && loading_state.is_ready {
            print("[NexaInference] Model already loaded, skipping")
            return
        }

        loading_state = .loading
        print("[NexaInference] State set to LOADING")

        do {
            // Unload previous model
            if llm_instance != nil {
                print("[NexaInference] Unloading previous model...")
                llm_instance = nil
            }

            // Initialize LLM
            print("[NexaInference] Creating LLM instance...")
            llm_instance = try LLM()
            print("[NexaInference] LLM instance created")

            // Create model options
            let model_options = ModelOptions(modelPath: model.local_file_url.path)
            print("[NexaInference] ModelOptions created with path: \(model.local_file_url.path)")

            // Load the model
            print("[NexaInference] Loading model (this may take a while)...")
            try await llm_instance?.load(model_options)
            print("[NexaInference] Model loaded successfully!")

            loaded_model = model
            loading_state = .ready
            print("[NexaInference] State set to READY")
            print("[NexaInference] ========== LOAD MODEL END (SUCCESS) ==========")

        } catch {
            let error_message = error.localizedDescription
            print("[NexaInference] ERROR loading model: \(error_message)")
            print("[NexaInference] Error type: \(type(of: error))")
            loading_state = .error(error_message)
            loaded_model = nil
            print("[NexaInference] ========== LOAD MODEL END (FAILURE) ==========")
            throw NexaInferenceError.model_initialization_failed(error_message)
        }
    }

    /// Unloads the current model
    func unload_model() {
        print("[NexaInference] Unloading model...")
        llm_instance = nil
        loaded_model = nil
        loading_state = .uninitialized
        print("[NexaInference] Model unloaded, state set to UNINITIALIZED")
    }

    /// Generates a streaming response for the conversation
    func generate_streaming_response(
        conversation_messages: [ChatMessageModel],
        system_prompt_context: String = "",
        token_handler: @escaping (String) -> Void
    ) async throws {
        print("[NexaInference] ========== GENERATE START ==========")
        print("[NexaInference] Message count: \(conversation_messages.count)")
        print("[NexaInference] loading_state.is_ready: \(loading_state.is_ready)")
        print("[NexaInference] llm_instance exists: \(llm_instance != nil)")

        guard loading_state.is_ready else {
            print("[NexaInference] ERROR: Model not ready!")
            throw NexaInferenceError.model_not_ready
        }

        guard let llm = llm_instance else {
            print("[NexaInference] ERROR: LLM instance is nil!")
            throw NexaInferenceError.model_not_ready
        }

        // Reset if stuck in generating state
        if is_currently_generating {
            print("[NexaInference] WARNING: Was stuck in generating state, resetting...")
            is_currently_generating = false
        }

        is_currently_generating = true
        should_cancel_generation = false
        print("[NexaInference] is_currently_generating set to TRUE")

        defer {
            is_currently_generating = false
            print("[NexaInference] is_currently_generating set to FALSE (defer)")
        }

        let nexa_messages = convert_to_nexa_messages(messages: conversation_messages, system_context: system_prompt_context)
        print("[NexaInference] Converted to \(nexa_messages.count) Nexa messages")
        for (index, msg) in nexa_messages.enumerated() {
            print("[NexaInference]   [\(index)] \(msg.role): \(String(msg.content.prefix(50)))...")
        }

        do {
            print("[NexaInference] Calling generateAsyncStream...")
            let stream = try await llm.generateAsyncStream(messages: nexa_messages)
            print("[NexaInference] Stream obtained, iterating tokens...")

            var token_count = 0
            var full_response = ""

            for try await token in stream {
                if should_cancel_generation {
                    print("[NexaInference] Generation cancelled by user at token \(token_count)")
                    llm.stopStream()
                    break
                }
                token_count += 1
                full_response += token
                token_handler(token)

                // Log every 10 tokens
                if token_count % 10 == 0 {
                    print("[NexaInference] Token \(token_count): total length \(full_response.count) chars")
                }
            }

            print("[NexaInference] Generation complete!")
            print("[NexaInference] Total tokens: \(token_count)")
            print("[NexaInference] Response preview: '\(full_response.prefix(100))...'")
            print("[NexaInference] ========== GENERATE END (SUCCESS) ==========")

        } catch {
            print("[NexaInference] ERROR during generation: \(error)")
            print("[NexaInference] Error type: \(type(of: error))")
            print("[NexaInference] ========== GENERATE END (FAILURE) ==========")
            throw NexaInferenceError.inference_failed(error.localizedDescription)
        }
    }

    /// Cancels any ongoing generation
    func cancel_current_generation() {
        print("[NexaInference] Cancel requested")
        should_cancel_generation = true
        llm_instance?.stopStream()
        is_currently_generating = false
    }

    // MARK: - Private Methods

    private func convert_to_nexa_messages(messages: [ChatMessageModel], system_context: String = "") -> [ChatMessage] {
        var nexa_messages: [ChatMessage] = []

        // Build system message with optional memory context
        var system_content = "You are a helpful AI assistant. Respond concisely and helpfully."

        if !system_context.isEmpty {
            system_content += system_context
        }

        nexa_messages.append(ChatMessage(
            role: .system,
            content: system_content
        ))

        // Convert conversation messages
        for message in messages {
            let role: Role
            switch message.message_role {
            case .user:
                role = .user
            case .assistant:
                role = .assistant
            case .system:
                role = .system
            }
            nexa_messages.append(ChatMessage(role: role, content: message.message_content))
        }

        return nexa_messages
    }
}
