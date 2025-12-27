import Foundation

/// A memory block containing reusable context/knowledge
struct MemoryBlock: Identifiable, Codable, Equatable {
    let block_id: UUID
    var block_title: String
    var block_content: String
    var block_created_timestamp: Date
    var block_updated_timestamp: Date
    var is_enabled: Bool

    var id: UUID { block_id }

    init(
        block_id: UUID = UUID(),
        block_title: String,
        block_content: String,
        is_enabled: Bool = true
    ) {
        self.block_id = block_id
        self.block_title = block_title
        self.block_content = block_content
        self.block_created_timestamp = Date()
        self.block_updated_timestamp = Date()
        self.is_enabled = is_enabled
    }

    /// Approximate token count for this memory block
    var estimated_token_count: Int {
        // Rough estimate: 1 token ≈ 4 characters
        (block_title.count + block_content.count) / 4
    }
}

/// A folder containing related memory blocks
struct MemoryFolder: Identifiable, Codable, Equatable {
    let folder_id: UUID
    var folder_name: String
    var folder_icon: String
    var folder_color: String
    var memory_blocks: [MemoryBlock]
    var folder_created_timestamp: Date
    var is_enabled: Bool

    var id: UUID { folder_id }

    init(
        folder_id: UUID = UUID(),
        folder_name: String,
        folder_icon: String = "folder.fill",
        folder_color: String = "blue",
        memory_blocks: [MemoryBlock] = [],
        is_enabled: Bool = true
    ) {
        self.folder_id = folder_id
        self.folder_name = folder_name
        self.folder_icon = folder_icon
        self.folder_color = folder_color
        self.memory_blocks = memory_blocks
        self.folder_created_timestamp = Date()
        self.is_enabled = is_enabled
    }

    /// Get all enabled memory blocks
    var enabled_blocks: [MemoryBlock] {
        memory_blocks.filter { $0.is_enabled }
    }

    /// Total estimated tokens for all enabled blocks
    var total_estimated_tokens: Int {
        enabled_blocks.reduce(0) { $0 + $1.estimated_token_count }
    }

    /// Format all enabled memories for system prompt inclusion
    func format_for_system_prompt() -> String {
        guard !enabled_blocks.isEmpty else { return "" }

        var result = "[\(folder_name) Knowledge]:\n"
        for block in enabled_blocks {
            result += "• \(block.block_title): \(block.block_content)\n"
        }
        return result
    }

    mutating func add_block(_ block: MemoryBlock) {
        memory_blocks.append(block)
    }

    mutating func remove_block(block_id: UUID) {
        memory_blocks.removeAll { $0.block_id == block_id }
    }

    mutating func update_block(_ block: MemoryBlock) {
        if let index = memory_blocks.firstIndex(where: { $0.block_id == block.block_id }) {
            memory_blocks[index] = block
        }
    }
}

/// Preset folder templates for quick setup
enum MemoryFolderTemplate: CaseIterable {
    case personal
    case work
    case code
    case preferences

    var folder: MemoryFolder {
        switch self {
        case .personal:
            return MemoryFolder(
                folder_name: "Personal",
                folder_icon: "person.fill",
                folder_color: "purple"
            )
        case .work:
            return MemoryFolder(
                folder_name: "Work",
                folder_icon: "briefcase.fill",
                folder_color: "blue"
            )
        case .code:
            return MemoryFolder(
                folder_name: "Code & Tech",
                folder_icon: "chevron.left.forwardslash.chevron.right",
                folder_color: "green"
            )
        case .preferences:
            return MemoryFolder(
                folder_name: "Preferences",
                folder_icon: "slider.horizontal.3",
                folder_color: "orange"
            )
        }
    }
}
