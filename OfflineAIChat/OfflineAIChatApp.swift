import SwiftUI

@main
struct OfflineAIChatApp: App {
    @StateObject private var app_state = AppState()

    var body: some Scene {
        WindowGroup {
            ChatConversationView(
                view_model: app_state.chat_view_model,
                download_service: app_state.download_service,
                inference_service: app_state.inference_service,
                storage_service: app_state.storage_service,
                memory_service: app_state.memory_service
            )
            .onAppear {
                print("[App] Main view appeared")
            }
        }
    }
}

/// Container class to properly manage @MainActor services
@MainActor
final class AppState: ObservableObject {
    let inference_service: NexaInferenceService
    let download_service: ModelDownloadService
    let storage_service: ChatStorageService
    let memory_service: MemoryStorageService
    let chat_view_model: ChatConversationViewModel

    init() {
        print("[AppState] Initializing app state...")

        // Create services
        let inference = NexaInferenceService()
        let download = ModelDownloadService()
        let storage = ChatStorageService()
        let memory = MemoryStorageService()

        self.inference_service = inference
        self.download_service = download
        self.storage_service = storage
        self.memory_service = memory

        // Create view model with all services
        let view_model = ChatConversationViewModel(inference_service: inference, storage_service: storage)
        view_model.set_memory_service(memory)
        self.chat_view_model = view_model

        print("[AppState] App state initialized with \(storage.saved_sessions.count) saved sessions")
        print("[AppState] Memory service has \(memory.memory_folders.count) folders with \(memory.enabled_memory_block_count) enabled blocks")
    }
}
