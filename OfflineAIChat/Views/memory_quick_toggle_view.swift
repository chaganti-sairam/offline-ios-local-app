import SwiftUI

/// Quick toggle popup for enabling/disabling memories during chat
struct MemoryQuickToggleView: View {
    @ObservedObject var memory_service: MemoryStorageService
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Summary header
                summary_header

                Divider()

                // Folder/block toggles
                if memory_service.memory_folders.isEmpty {
                    empty_state
                } else {
                    toggle_list
                }
            }
            .navigationTitle("Active Memories")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.medium)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    private var summary_header: some View {
        HStack(spacing: 16) {
            // Token usage
            VStack(alignment: .leading, spacing: 4) {
                Text("Context Used")
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack(spacing: 4) {
                    Image(systemName: "brain.head.profile")
                        .font(.subheadline)
                        .foregroundColor(.purple)

                    Text("~\(memory_service.total_enabled_memory_tokens) tokens")
                        .font(.subheadline.bold())
                }
            }

            Spacer()

            // Active count
            VStack(alignment: .trailing, spacing: 4) {
                Text("Active Blocks")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text("\(memory_service.enabled_memory_block_count)")
                    .font(.title2.bold())
                    .foregroundColor(.blue)
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
    }

    private var toggle_list: some View {
        List {
            ForEach(memory_service.memory_folders) { folder in
                Section {
                    // Folder toggle
                    folder_toggle_row(folder: folder)

                    // Block toggles (only show if folder is enabled)
                    if folder.is_enabled {
                        ForEach(folder.memory_blocks) { block in
                            block_toggle_row(folder: folder, block: block)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private func folder_toggle_row(folder: MemoryFolder) -> some View {
        HStack(spacing: 12) {
            Image(systemName: folder.folder_icon)
                .font(.system(size: 18))
                .foregroundColor(color_from_string(folder.folder_color))
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(folder.folder_name)
                    .font(.headline)

                Text("\(folder.enabled_blocks.count)/\(folder.memory_blocks.count) blocks • ~\(folder.total_estimated_tokens) tokens")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Toggle("", isOn: Binding(
                get: { folder.is_enabled },
                set: { new_value in
                    memory_service.toggle_folder_enabled(folder_id: folder.folder_id, is_enabled: new_value)
                }
            ))
            .labelsHidden()
        }
        .padding(.vertical, 4)
    }

    private func block_toggle_row(folder: MemoryFolder, block: MemoryBlock) -> some View {
        HStack(spacing: 10) {
            // Compact 1-line view
            Text(block.block_title)
                .font(.subheadline)
                .lineLimit(1)
                .foregroundColor(block.is_enabled ? .primary : .secondary)

            Spacer()

            Text("\(block.estimated_token_count)")
                .font(.caption2.monospacedDigit())
                .foregroundColor(.secondary)

            Toggle("", isOn: Binding(
                get: { block.is_enabled },
                set: { new_value in
                    var updated_block = block
                    updated_block.is_enabled = new_value
                    memory_service.update_block_in_folder(folder_id: folder.folder_id, block: updated_block)
                }
            ))
            .labelsHidden()
            .scaleEffect(0.85)
        }
        .padding(.leading, 20)
    }

    private var empty_state: some View {
        VStack(spacing: 16) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 50))
                .foregroundColor(.secondary.opacity(0.5))

            Text("No Memories Yet")
                .font(.headline)

            Text("Add memories in Settings to give the AI context about you")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func color_from_string(_ color_name: String) -> Color {
        switch color_name.lowercased() {
        case "blue": return .blue
        case "purple": return .purple
        case "green": return .green
        case "orange": return .orange
        case "red": return .red
        case "pink": return .pink
        case "yellow": return .yellow
        default: return .blue
        }
    }
}

#Preview {
    MemoryQuickToggleView(memory_service: MemoryStorageService())
}
