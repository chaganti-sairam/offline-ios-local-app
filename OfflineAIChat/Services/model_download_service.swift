import Foundation
import SwiftUI

/// Model category for organization
enum ModelCategory: String, CaseIterable {
    case fast = "Fast & Light"
    case balanced = "Balanced"
    case quality = "High Quality"
    case coding = "Code Focused"

    var description: String {
        switch self {
        case .fast: return "Quick responses, low memory"
        case .balanced: return "Good quality, moderate speed"
        case .quality: return "Best quality, needs more RAM"
        case .coding: return "Optimized for code tasks"
        }
    }
}

/// Available models for download
enum AvailableModel: String, CaseIterable, Identifiable {
    // Fast & Light (< 1B params)
    case qwen3_0_6b = "Qwen3-0.6B"
    case tinyllama_1_1b = "TinyLlama-1.1B"

    // Balanced (1-2B params)
    case qwen2_5_1_5b = "Qwen2.5-1.5B"
    case gemma2_2b = "Gemma2-2B"
    case phi3_mini = "Phi3-Mini"

    // High Quality (3B+ params)
    case llama3_2_3b = "Llama3.2-3B"
    case qwen2_5_3b = "Qwen2.5-3B"
    case mistral_7b = "Mistral-7B"

    // Code Focused
    case starcoder2_3b = "StarCoder2-3B"
    case deepseek_coder_1_3b = "DeepSeek-Coder-1.3B"

    var id: String { rawValue }

    var category: ModelCategory {
        switch self {
        case .qwen3_0_6b, .tinyllama_1_1b:
            return .fast
        case .qwen2_5_1_5b, .gemma2_2b, .phi3_mini:
            return .balanced
        case .llama3_2_3b, .qwen2_5_3b, .mistral_7b:
            return .quality
        case .starcoder2_3b, .deepseek_coder_1_3b:
            return .coding
        }
    }

    var display_name: String {
        switch self {
        case .qwen3_0_6b: return "Qwen3 0.6B"
        case .tinyllama_1_1b: return "TinyLlama 1.1B"
        case .qwen2_5_1_5b: return "Qwen2.5 1.5B"
        case .gemma2_2b: return "Gemma 2 2B"
        case .phi3_mini: return "Phi-3 Mini"
        case .llama3_2_3b: return "Llama 3.2 3B"
        case .qwen2_5_3b: return "Qwen2.5 3B"
        case .mistral_7b: return "Mistral 7B"
        case .starcoder2_3b: return "StarCoder2 3B"
        case .deepseek_coder_1_3b: return "DeepSeek Coder 1.3B"
        }
    }

    var description: String {
        switch self {
        case .qwen3_0_6b: return "Ultra-fast responses, basic tasks"
        case .tinyllama_1_1b: return "Quick chat, simple questions"
        case .qwen2_5_1_5b: return "Good balance of speed and quality"
        case .gemma2_2b: return "Google's efficient model"
        case .phi3_mini: return "Microsoft's compact powerhouse"
        case .llama3_2_3b: return "Meta's latest, great reasoning"
        case .qwen2_5_3b: return "Excellent multilingual support"
        case .mistral_7b: return "Best quality, needs more RAM"
        case .starcoder2_3b: return "Optimized for code generation"
        case .deepseek_coder_1_3b: return "Fast code assistant"
        }
    }

    var file_name: String {
        switch self {
        case .qwen3_0_6b: return "Qwen3-0.6B-Q8_0.gguf"
        case .tinyllama_1_1b: return "tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf"
        case .qwen2_5_1_5b: return "qwen2.5-1.5b-instruct-q4_k_m.gguf"
        case .gemma2_2b: return "gemma-2-2b-it-Q4_K_M.gguf"
        case .phi3_mini: return "Phi-3-mini-4k-instruct-q4.gguf"
        case .llama3_2_3b: return "Llama-3.2-3B-Instruct-Q4_K_M.gguf"
        case .qwen2_5_3b: return "qwen2.5-3b-instruct-q4_k_m.gguf"
        case .mistral_7b: return "mistral-7b-instruct-v0.2.Q4_K_M.gguf"
        case .starcoder2_3b: return "starcoder2-3b-Q4_K_M.gguf"
        case .deepseek_coder_1_3b: return "deepseek-coder-1.3b-instruct.Q4_K_M.gguf"
        }
    }

    var download_url: URL {
        switch self {
        case .qwen3_0_6b:
            return URL(string: "https://huggingface.co/Qwen/Qwen3-0.6B-GGUF/resolve/main/Qwen3-0.6B-Q8_0.gguf")!
        case .tinyllama_1_1b:
            return URL(string: "https://huggingface.co/TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF/resolve/main/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf")!
        case .qwen2_5_1_5b:
            return URL(string: "https://huggingface.co/Qwen/Qwen2.5-1.5B-Instruct-GGUF/resolve/main/qwen2.5-1.5b-instruct-q4_k_m.gguf")!
        case .gemma2_2b:
            return URL(string: "https://huggingface.co/bartowski/gemma-2-2b-it-GGUF/resolve/main/gemma-2-2b-it-Q4_K_M.gguf")!
        case .phi3_mini:
            return URL(string: "https://huggingface.co/microsoft/Phi-3-mini-4k-instruct-gguf/resolve/main/Phi-3-mini-4k-instruct-q4.gguf")!
        case .llama3_2_3b:
            return URL(string: "https://huggingface.co/bartowski/Llama-3.2-3B-Instruct-GGUF/resolve/main/Llama-3.2-3B-Instruct-Q4_K_M.gguf")!
        case .qwen2_5_3b:
            return URL(string: "https://huggingface.co/Qwen/Qwen2.5-3B-Instruct-GGUF/resolve/main/qwen2.5-3b-instruct-q4_k_m.gguf")!
        case .mistral_7b:
            return URL(string: "https://huggingface.co/TheBloke/Mistral-7B-Instruct-v0.2-GGUF/resolve/main/mistral-7b-instruct-v0.2.Q4_K_M.gguf")!
        case .starcoder2_3b:
            return URL(string: "https://huggingface.co/second-state/StarCoder2-3B-GGUF/resolve/main/starcoder2-3b-Q4_K_M.gguf")!
        case .deepseek_coder_1_3b:
            return URL(string: "https://huggingface.co/TheBloke/deepseek-coder-1.3b-instruct-GGUF/resolve/main/deepseek-coder-1.3b-instruct.Q4_K_M.gguf")!
        }
    }

    var estimated_size_mb: Int {
        switch self {
        case .qwen3_0_6b: return 639
        case .tinyllama_1_1b: return 638
        case .qwen2_5_1_5b: return 986
        case .gemma2_2b: return 1500
        case .phi3_mini: return 2200
        case .llama3_2_3b: return 2000
        case .qwen2_5_3b: return 1900
        case .mistral_7b: return 4100
        case .starcoder2_3b: return 1800
        case .deepseek_coder_1_3b: return 800
        }
    }

    /// Context length in tokens
    var context_length: Int {
        switch self {
        case .qwen3_0_6b: return 8192
        case .tinyllama_1_1b: return 2048
        case .qwen2_5_1_5b: return 32768
        case .gemma2_2b: return 8192
        case .phi3_mini: return 4096
        case .llama3_2_3b: return 8192
        case .qwen2_5_3b: return 32768
        case .mistral_7b: return 8192
        case .starcoder2_3b: return 4096
        case .deepseek_coder_1_3b: return 16384
        }
    }

    /// Actual RAM usage when loaded (in MB) - approximately 1.2-1.5x file size for Q4 models
    var ram_usage_mb: Int {
        switch self {
        case .qwen3_0_6b: return 750          // 0.6B model
        case .tinyllama_1_1b: return 800      // 1.1B model
        case .deepseek_coder_1_3b: return 950 // 1.3B model
        case .qwen2_5_1_5b: return 1100       // 1.5B model
        case .gemma2_2b: return 1700          // 2B model
        case .phi3_mini: return 2500          // 3.8B model
        case .llama3_2_3b: return 2300        // 3B model
        case .qwen2_5_3b: return 2200         // 3B model
        case .starcoder2_3b: return 2100      // 3B model
        case .mistral_7b: return 4800         // 7B model
        }
    }

    /// Formatted RAM usage string
    var ram_usage_formatted: String {
        if ram_usage_mb >= 1000 {
            let gb = Double(ram_usage_mb) / 1000.0
            return String(format: "%.1fGB", gb)
        }
        return "\(ram_usage_mb)MB"
    }

    var local_file_url: URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documents.appendingPathComponent(file_name)
    }

    var is_downloaded: Bool {
        FileManager.default.fileExists(atPath: local_file_url.path)
    }

    /// Models grouped by category
    static var by_category: [ModelCategory: [AvailableModel]] {
        Dictionary(grouping: allCases, by: { $0.category })
    }
}

/// Download state for a model
enum ModelDownloadState: Equatable {
    case not_downloaded
    case downloading(progress: Double)
    case downloaded
    case failed(error: String)
}

/// Service for managing model downloads with resume support
@MainActor
final class ModelDownloadService: NSObject, ObservableObject {

    // MARK: - Published Properties

    @Published var download_states: [AvailableModel: ModelDownloadState] = [:]
    @Published var active_model: AvailableModel?

    // MARK: - Private Properties

    private var download_tasks: [AvailableModel: URLSessionDownloadTask] = [:]
    private var resume_data: [AvailableModel: Data] = [:]
    private var background_session: URLSession!
    private var download_continuations: [AvailableModel: CheckedContinuation<URL, Error>] = [:]

    // MARK: - Initialization

    override init() {
        super.init()
        setup_background_session()
        load_initial_states()
        load_active_model()
    }

    private func setup_background_session() {
        let config = URLSessionConfiguration.background(withIdentifier: "com.offlineai.chat.download")
        config.isDiscretionary = false
        config.sessionSendsLaunchEvents = true
        config.timeoutIntervalForRequest = 600
        config.timeoutIntervalForResource = 3600
        background_session = URLSession(configuration: config, delegate: self, delegateQueue: .main)
    }

    private func load_initial_states() {
        for model in AvailableModel.allCases {
            if model.is_downloaded {
                download_states[model] = .downloaded
            } else {
                download_states[model] = .not_downloaded
            }
        }
    }

    private func load_active_model() {
        if let saved_model = UserDefaults.standard.string(forKey: "active_model"),
           let model = AvailableModel(rawValue: saved_model),
           model.is_downloaded {
            active_model = model
        } else {
            // Set first downloaded model as active
            active_model = AvailableModel.allCases.first { $0.is_downloaded }
        }
    }

    // MARK: - Public Methods

    func set_active_model(_ model: AvailableModel) {
        guard model.is_downloaded else { return }
        active_model = model
        UserDefaults.standard.set(model.rawValue, forKey: "active_model")
    }

    func start_download(model: AvailableModel) async throws -> URL {
        // Check if already downloaded
        if model.is_downloaded {
            download_states[model] = .downloaded
            return model.local_file_url
        }

        // Check if already downloading
        if case .downloading = download_states[model] {
            throw DownloadError.already_downloading
        }

        download_states[model] = .downloading(progress: 0)
        print("[ModelDownloadService] Starting download for \(model.display_name)")

        return try await withCheckedThrowingContinuation { continuation in
            download_continuations[model] = continuation

            var request = URLRequest(url: model.download_url)
            request.timeoutInterval = 600

            // Check for resume data
            if let resume = resume_data[model] {
                print("[ModelDownloadService] Resuming download for \(model.display_name)")
                let task = background_session.downloadTask(withResumeData: resume)
                download_tasks[model] = task
                task.resume()
            } else {
                let task = background_session.downloadTask(with: request)
                download_tasks[model] = task
                task.resume()
            }
        }
    }

    func cancel_download(model: AvailableModel) {
        download_tasks[model]?.cancel { [weak self] data in
            Task { @MainActor in
                if let data = data {
                    self?.resume_data[model] = data
                    print("[ModelDownloadService] Saved resume data for \(model.display_name)")
                }
            }
        }
        download_tasks[model] = nil
        download_states[model] = .not_downloaded
    }

    func delete_model(model: AvailableModel) {
        try? FileManager.default.removeItem(at: model.local_file_url)
        download_states[model] = .not_downloaded
        resume_data[model] = nil

        if active_model == model {
            active_model = AvailableModel.allCases.first { $0.is_downloaded }
        }
    }

    func get_download_progress(model: AvailableModel) -> Double {
        if case .downloading(let progress) = download_states[model] {
            return progress
        }
        return 0
    }
}

// MARK: - URLSessionDownloadDelegate

extension ModelDownloadService: URLSessionDownloadDelegate {

    nonisolated func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        // IMPORTANT: Must copy file synchronously before this method returns!
        // The temp file at `location` is deleted immediately after this method returns.

        // First, find which model this is for (need to check on main actor)
        // We'll copy to a temp location first, then move on main actor
        let file_manager = FileManager.default
        let temp_copy = file_manager.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".gguf")

        do {
            // Copy to our own temp location synchronously
            try file_manager.copyItem(at: location, to: temp_copy)
            print("[ModelDownloadService] Copied download to temp: \(temp_copy.path)")

            // Now update state on main actor
            Task { @MainActor in
                guard let model = self.download_tasks.first(where: { $0.value == downloadTask })?.key else {
                    print("[ModelDownloadService] Unknown download task completed")
                    try? file_manager.removeItem(at: temp_copy)
                    return
                }

                do {
                    // Move to permanent location
                    if file_manager.fileExists(atPath: model.local_file_url.path) {
                        try file_manager.removeItem(at: model.local_file_url)
                    }
                    try file_manager.moveItem(at: temp_copy, to: model.local_file_url)

                    print("[ModelDownloadService] Download complete for \(model.display_name) at \(model.local_file_url.path)")
                    self.download_states[model] = .downloaded
                    self.download_tasks[model] = nil
                    self.resume_data[model] = nil

                    // Set as active if no active model
                    if self.active_model == nil {
                        self.set_active_model(model)
                    }

                    self.download_continuations[model]?.resume(returning: model.local_file_url)
                    self.download_continuations[model] = nil

                } catch {
                    print("[ModelDownloadService] Failed to save model: \(error)")
                    self.download_states[model] = .failed(error: error.localizedDescription)
                    self.download_continuations[model]?.resume(throwing: error)
                    self.download_continuations[model] = nil
                    try? file_manager.removeItem(at: temp_copy)
                }
            }
        } catch {
            print("[ModelDownloadService] Failed to copy download: \(error)")
            Task { @MainActor in
                if let model = self.download_tasks.first(where: { $0.value == downloadTask })?.key {
                    self.download_states[model] = .failed(error: "Failed to save: \(error.localizedDescription)")
                    self.download_continuations[model]?.resume(throwing: error)
                    self.download_continuations[model] = nil
                }
            }
        }
    }

    nonisolated func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        Task { @MainActor in
            guard let model = download_tasks.first(where: { $0.value == downloadTask })?.key else { return }

            let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
            download_states[model] = .downloading(progress: progress)

            // Log every 5%
            let percent = Int(progress * 100)
            if percent % 5 == 0 {
                print("[ModelDownloadService] \(model.display_name): \(percent)% (\(totalBytesWritten / 1024 / 1024)MB / \(totalBytesExpectedToWrite / 1024 / 1024)MB)")
            }
        }
    }

    nonisolated func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        Task { @MainActor in
            guard let download_task = task as? URLSessionDownloadTask,
                  let model = download_tasks.first(where: { $0.value == download_task })?.key else { return }

            if let error = error {
                let ns_error = error as NSError

                // Save resume data if available
                if let resume = ns_error.userInfo[NSURLSessionDownloadTaskResumeData] as? Data {
                    resume_data[model] = resume
                    print("[ModelDownloadService] Download interrupted, resume data saved for \(model.display_name)")
                }

                print("[ModelDownloadService] Download failed for \(model.display_name): \(error.localizedDescription)")
                download_states[model] = .failed(error: error.localizedDescription)
                download_tasks[model] = nil

                download_continuations[model]?.resume(throwing: error)
                download_continuations[model] = nil
            }
        }
    }

    nonisolated func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        print("[ModelDownloadService] Background session events finished")
    }
}

// MARK: - Errors

enum DownloadError: Error, LocalizedError {
    case already_downloading
    case download_failed(String)

    var errorDescription: String? {
        switch self {
        case .already_downloading:
            return "Download already in progress"
        case .download_failed(let reason):
            return "Download failed: \(reason)"
        }
    }
}
