import Foundation

/// Service for persisting and managing memory folders and blocks
@MainActor
final class MemoryStorageService: ObservableObject {

    // MARK: - Published Properties

    @Published var memory_folders: [MemoryFolder] = []

    // MARK: - Private Properties

    private let file_manager = FileManager.default
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private var storage_file_url: URL {
        let documents = file_manager.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documents.appendingPathComponent("memories.json")
    }

    // MARK: - Initialization

    init() {
        load_memories()
    }

    // MARK: - Public Methods - Folders

    /// Creates a new memory folder
    func create_folder(_ folder: MemoryFolder) {
        memory_folders.append(folder)
        save_memories()
    }

    /// Creates a folder from template
    func create_folder_from_template(_ template: MemoryFolderTemplate) {
        create_folder(template.folder)
    }

    /// Updates an existing folder
    func update_folder(_ folder: MemoryFolder) {
        if let index = memory_folders.firstIndex(where: { $0.folder_id == folder.folder_id }) {
            memory_folders[index] = folder
            save_memories()
        }
    }

    /// Deletes a folder
    func delete_folder(folder_id: UUID) {
        memory_folders.removeAll { $0.folder_id == folder_id }
        save_memories()
    }

    /// Toggles folder enabled state
    func toggle_folder(folder_id: UUID) {
        if let index = memory_folders.firstIndex(where: { $0.folder_id == folder_id }) {
            memory_folders[index].is_enabled.toggle()
            save_memories()
        }
    }

    /// Sets folder enabled state explicitly
    func toggle_folder_enabled(folder_id: UUID, is_enabled: Bool) {
        if let index = memory_folders.firstIndex(where: { $0.folder_id == folder_id }) {
            memory_folders[index].is_enabled = is_enabled
            save_memories()
        }
    }

    /// Updates a block in a folder (alias for update_block)
    func update_block_in_folder(folder_id: UUID, block: MemoryBlock) {
        update_block(in: folder_id, block: block)
    }

    // MARK: - Public Methods - Blocks

    /// Adds a memory block to a folder
    func add_block(to folder_id: UUID, block: MemoryBlock) {
        if let index = memory_folders.firstIndex(where: { $0.folder_id == folder_id }) {
            memory_folders[index].add_block(block)
            save_memories()
        }
    }

    /// Updates a memory block
    func update_block(in folder_id: UUID, block: MemoryBlock) {
        if let index = memory_folders.firstIndex(where: { $0.folder_id == folder_id }) {
            memory_folders[index].update_block(block)
            save_memories()
        }
    }

    /// Deletes a memory block
    func delete_block(from folder_id: UUID, block_id: UUID) {
        if let index = memory_folders.firstIndex(where: { $0.folder_id == folder_id }) {
            memory_folders[index].remove_block(block_id: block_id)
            save_memories()
        }
    }

    /// Toggles block enabled state
    func toggle_block(in folder_id: UUID, block_id: UUID) {
        if let folder_index = memory_folders.firstIndex(where: { $0.folder_id == folder_id }),
           let block_index = memory_folders[folder_index].memory_blocks.firstIndex(where: { $0.block_id == block_id }) {
            memory_folders[folder_index].memory_blocks[block_index].is_enabled.toggle()
            save_memories()
        }
    }

    // MARK: - Context Generation

    /// Gets all enabled memories formatted for system prompt
    func get_formatted_memories_for_prompt() -> String {
        let enabled_folders = memory_folders.filter { $0.is_enabled && !$0.enabled_blocks.isEmpty }
        guard !enabled_folders.isEmpty else { return "" }

        var result = "\n\n[User's Personal Knowledge Base]:\n"
        for folder in enabled_folders {
            result += folder.format_for_system_prompt()
            result += "\n"
        }
        return result
    }

    /// Total estimated tokens for all enabled memories
    var total_enabled_memory_tokens: Int {
        memory_folders
            .filter { $0.is_enabled }
            .reduce(0) { $0 + $1.total_estimated_tokens }
    }

    /// Count of all enabled memory blocks
    var enabled_memory_block_count: Int {
        memory_folders
            .filter { $0.is_enabled }
            .reduce(0) { $0 + $1.enabled_blocks.count }
    }

    // MARK: - Private Methods

    private func load_memories() {
        guard file_manager.fileExists(atPath: storage_file_url.path) else {
            print("[MemoryStorage] No existing memories file")
            return
        }

        do {
            let data = try Data(contentsOf: storage_file_url)
            memory_folders = try decoder.decode([MemoryFolder].self, from: data)
            print("[MemoryStorage] Loaded \(memory_folders.count) folders")
        } catch {
            print("[MemoryStorage] Error loading memories: \(error)")
        }
    }

    private func save_memories() {
        do {
            let data = try encoder.encode(memory_folders)
            try data.write(to: storage_file_url)
            print("[MemoryStorage] Saved \(memory_folders.count) folders")
        } catch {
            print("[MemoryStorage] Error saving memories: \(error)")
        }
    }
}
