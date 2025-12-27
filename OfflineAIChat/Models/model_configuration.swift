import Foundation

/// Configuration constants for the AI model
struct ModelConfiguration {

    // MARK: - Model File Settings

    /// The filename of the bundled GGUF model (without extension)
    static let bundled_model_name = "tinyllama-1.1b-chat-v1.0.Q4_K_M"

    /// The file extension of the model
    static let model_file_extension = "gguf"

    /// Full filename with extension
    static let bundled_model_filename = "\(bundled_model_name).\(model_file_extension)"

    // MARK: - Generation Parameters

    /// Maximum context length the model can handle
    static let model_context_length = 2048

    /// Maximum tokens to generate per response
    static let maximum_tokens_per_response = 512

    /// Temperature for generation (higher = more creative)
    static let generation_temperature: Float = 0.7

    /// Top-p (nucleus) sampling threshold
    static let generation_top_p: Float = 0.9

    /// Repeat penalty to avoid repetitive outputs
    static let generation_repeat_penalty: Float = 1.1

    // MARK: - Memory Management

    /// Maximum number of messages to keep in context
    static let maximum_messages_in_context = 20

    /// Minimum time between generations (seconds) to prevent thermal issues
    static let minimum_seconds_between_generations: TimeInterval = 0.5

    // MARK: - System Prompt

    /// Default system prompt for the assistant
    static let default_system_prompt = """
    You are a helpful AI assistant running locally on an iPhone. \
    You provide concise, accurate responses. \
    If you don't know something, say so honestly.
    """

    // MARK: - Model Loading State

    /// Represents the current state of model loading
    enum ModelLoadingState: Equatable {
        case uninitialized
        case loading_model
        case model_ready
        case error_loading_failed(String)

        var is_ready: Bool {
            if case .model_ready = self { return true }
            return false
        }

        var is_loading: Bool {
            if case .loading_model = self { return true }
            return false
        }

        var error_description: String? {
            if case .error_loading_failed(let message) = self {
                return message
            }
            return nil
        }
    }

    // MARK: - File URL Helpers

    /// Returns the URL to the bundled model file, if it exists
    static func bundled_model_file_url() -> URL? {
        guard let model_path = Bundle.main.path(
            forResource: bundled_model_name,
            ofType: model_file_extension
        ) else {
            return nil
        }
        return URL(fileURLWithPath: model_path)
    }

    /// Returns the URL to the models directory in the bundle
    static func bundled_models_directory_url() -> URL? {
        guard let model_url = bundled_model_file_url() else {
            return nil
        }
        return model_url.deletingLastPathComponent()
    }

    /// Returns the URL to the documents directory for storing downloaded models
    static func documents_models_directory_url() -> URL {
        let documents_url = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first!
        return documents_url.appendingPathComponent("Models", isDirectory: true)
    }

    /// Creates the documents models directory if it doesn't exist
    static func ensure_documents_models_directory_exists() throws {
        let models_directory = documents_models_directory_url()
        if !FileManager.default.fileExists(atPath: models_directory.path) {
            try FileManager.default.createDirectory(
                at: models_directory,
                withIntermediateDirectories: true,
                attributes: nil
            )
        }
    }
}
