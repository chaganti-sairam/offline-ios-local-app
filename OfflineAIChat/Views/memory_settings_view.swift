import SwiftUI

/// Settings view for managing memory folders and blocks
struct MemorySettingsView: View {
    @ObservedObject var memory_service: MemoryStorageService
    @State private var show_add_folder_sheet: Bool = false
    @State private var folder_to_edit: MemoryFolder?
    @State private var folder_to_add_block: MemoryFolder?
    @State private var block_to_edit: (folder: MemoryFolder, block: MemoryBlock)?

    var body: some View {
        List {
            // Overview section
            overview_section

            // Folders section
            if memory_service.memory_folders.isEmpty {
                empty_state_section
            } else {
                folders_section
            }

            // Templates section
            templates_section
        }
        .sheet(isPresented: $show_add_folder_sheet) {
            FolderEditorSheet(
                memory_service: memory_service,
                existing_folder: nil
            )
        }
        .sheet(item: $folder_to_edit) { folder in
            FolderEditorSheet(
                memory_service: memory_service,
                existing_folder: folder
            )
        }
        .sheet(item: $folder_to_add_block) { folder in
            BlockEditorSheet(
                memory_service: memory_service,
                folder: folder,
                existing_block: nil
            )
        }
        .sheet(item: Binding(
            get: { block_to_edit?.block },
            set: { _ in block_to_edit = nil }
        )) { block in
            if let folder = block_to_edit?.folder {
                BlockEditorSheet(
                    memory_service: memory_service,
                    folder: folder,
                    existing_block: block
                )
            }
        }
    }

    // MARK: - Overview Section

    private var overview_section: some View {
        Section {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Memory Tokens")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    HStack(spacing: 4) {
                        Text("~\(memory_service.total_enabled_memory_tokens)")
                            .font(.title2.monospacedDigit().bold())
                        Text("tokens")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Active Blocks")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text("\(memory_service.enabled_memory_block_count)")
                        .font(.title2.monospacedDigit().bold())
                        .foregroundColor(.purple)
                }
            }
            .padding(.vertical, 8)
        } header: {
            Label("Overview", systemImage: "chart.bar.fill")
        } footer: {
            Text("Enabled memories are included in every chat as context. More tokens = more context = better responses.")
        }
    }

    // MARK: - Empty State

    private var empty_state_section: some View {
        Section {
            VStack(spacing: 16) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 40))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text("No Memories Yet")
                    .font(.headline)

                Text("Create folders to store reusable context like your preferences, work info, or coding style.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                Button(action: { show_add_folder_sheet = true }) {
                    Label("Create First Folder", systemImage: "plus.circle.fill")
                        .font(.headline)
                }
                .buttonStyle(.borderedProminent)
                .tint(.purple)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
        }
    }

    // MARK: - Folders Section

    private var folders_section: some View {
        Section {
            ForEach(memory_service.memory_folders) { folder in
                FolderRowView(
                    folder: folder,
                    memory_service: memory_service,
                    on_edit: { folder_to_edit = folder },
                    on_add_block: { folder_to_add_block = folder },
                    on_edit_block: { block in
                        block_to_edit = (folder: folder, block: block)
                    }
                )
            }
            .onDelete(perform: delete_folders)

            Button(action: { show_add_folder_sheet = true }) {
                Label("Add Folder", systemImage: "folder.badge.plus")
            }
        } header: {
            Label("Memory Folders", systemImage: "folder.fill")
        }
    }

    // MARK: - Templates Section

    private var templates_section: some View {
        Section {
            ForEach(MemoryFolderTemplate.allCases, id: \.self) { template in
                let folder = template.folder
                let already_exists = memory_service.memory_folders.contains { $0.folder_name == folder.folder_name }

                Button(action: {
                    if !already_exists {
                        memory_service.create_folder_from_template(template)
                    }
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: folder.folder_icon)
                            .font(.title3)
                            .foregroundColor(color_from_string(folder.folder_color))
                            .frame(width: 30)

                        Text(folder.folder_name)
                            .foregroundColor(already_exists ? .secondary : .primary)

                        Spacer()

                        if already_exists {
                            Text("Added")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            Image(systemName: "plus.circle")
                                .foregroundColor(.blue)
                        }
                    }
                }
                .disabled(already_exists)
            }
        } header: {
            Label("Quick Add Templates", systemImage: "sparkles")
        } footer: {
            Text("Tap to quickly add pre-configured folder structures.")
        }
    }

    // MARK: - Actions

    private func delete_folders(at offsets: IndexSet) {
        for index in offsets {
            let folder = memory_service.memory_folders[index]
            memory_service.delete_folder(folder_id: folder.folder_id)
        }
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
        case "cyan": return .cyan
        default: return .blue
        }
    }
}

// MARK: - Folder Row View

struct FolderRowView: View {
    let folder: MemoryFolder
    @ObservedObject var memory_service: MemoryStorageService
    let on_edit: () -> Void
    let on_add_block: () -> Void
    let on_edit_block: (MemoryBlock) -> Void

    @State private var is_expanded: Bool = false

    private func color_from_string(_ color_name: String) -> Color {
        switch color_name.lowercased() {
        case "blue": return .blue
        case "purple": return .purple
        case "green": return .green
        case "orange": return .orange
        case "red": return .red
        case "pink": return .pink
        case "yellow": return .yellow
        case "cyan": return .cyan
        default: return .blue
        }
    }

    var body: some View {
        DisclosureGroup(isExpanded: $is_expanded) {
            // Memory blocks
            if folder.memory_blocks.isEmpty {
                HStack {
                    Text("No memories in this folder")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .italic()
                    Spacer()
                }
                .padding(.vertical, 4)
            } else {
                ForEach(folder.memory_blocks) { block in
                    BlockRowView(
                        block: block,
                        folder_id: folder.folder_id,
                        memory_service: memory_service,
                        on_edit: { on_edit_block(block) }
                    )
                }
            }

            // Add block button
            Button(action: on_add_block) {
                Label("Add Memory", systemImage: "plus")
                    .font(.subheadline)
            }
            .padding(.vertical, 4)
        } label: {
            HStack(spacing: 12) {
                // Folder icon
                Image(systemName: folder.folder_icon)
                    .font(.title3)
                    .foregroundColor(color_from_string(folder.folder_color))
                    .frame(width: 28)

                // Folder name and stats
                VStack(alignment: .leading, spacing: 2) {
                    Text(folder.folder_name)
                        .font(.headline)

                    HStack(spacing: 8) {
                        Text("\(folder.memory_blocks.count) items")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        if folder.total_estimated_tokens > 0 {
                            Text("•")
                                .foregroundColor(.secondary)
                            Text("~\(folder.total_estimated_tokens) tokens")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Spacer()

                // Toggle enabled
                Toggle("", isOn: Binding(
                    get: { folder.is_enabled },
                    set: { _ in memory_service.toggle_folder(folder_id: folder.folder_id) }
                ))
                .labelsHidden()
            }
            .contentShape(Rectangle())
            .contextMenu {
                Button(action: on_edit) {
                    Label("Edit Folder", systemImage: "pencil")
                }

                Button(action: on_add_block) {
                    Label("Add Memory", systemImage: "plus")
                }

                Divider()

                Button(role: .destructive, action: {
                    memory_service.delete_folder(folder_id: folder.folder_id)
                }) {
                    Label("Delete Folder", systemImage: "trash")
                }
            }
        }
    }
}

// MARK: - Block Row View

struct BlockRowView: View {
    let block: MemoryBlock
    let folder_id: UUID
    @ObservedObject var memory_service: MemoryStorageService
    let on_edit: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            // Compact 1-line content
            Text(block.block_title)
                .font(.subheadline)
                .lineLimit(1)
                .foregroundColor(block.is_enabled ? .primary : .secondary)

            Spacer()

            // Token count badge
            Text("\(block.estimated_token_count)")
                .font(.caption2.monospacedDigit())
                .foregroundColor(.secondary)
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(Color.gray.opacity(0.1), in: Capsule())

            // Toggle
            Toggle("", isOn: Binding(
                get: { block.is_enabled },
                set: { _ in memory_service.toggle_block(in: folder_id, block_id: block.block_id) }
            ))
            .labelsHidden()
            .scaleEffect(0.85)
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle())
        .onTapGesture(perform: on_edit)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                memory_service.delete_block(from: folder_id, block_id: block.block_id)
            } label: {
                Label("Delete", systemImage: "trash")
            }

            Button(action: on_edit) {
                Label("Edit", systemImage: "pencil")
            }
            .tint(.blue)
        }
    }
}

// MARK: - Folder Editor Sheet

struct FolderEditorSheet: View {
    @ObservedObject var memory_service: MemoryStorageService
    let existing_folder: MemoryFolder?
    @Environment(\.dismiss) private var dismiss

    @State private var folder_name: String = ""
    @State private var folder_icon: String = "folder.fill"
    @State private var folder_color: String = "blue"

    private let available_icons = [
        "folder.fill", "person.fill", "briefcase.fill", "doc.fill",
        "book.fill", "star.fill", "heart.fill", "lightbulb.fill",
        "chevron.left.forwardslash.chevron.right", "slider.horizontal.3",
        "gearshape.fill", "house.fill", "building.2.fill", "airplane"
    ]

    private let available_colors = ["blue", "purple", "green", "orange", "red", "pink", "cyan"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Folder Name") {
                    TextField("e.g., Work, Personal, Coding", text: $folder_name)
                }

                Section("Icon") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 50))], spacing: 12) {
                        ForEach(available_icons, id: \.self) { icon in
                            Button(action: { folder_icon = icon }) {
                                Image(systemName: icon)
                                    .font(.title2)
                                    .foregroundColor(folder_icon == icon ? color_from_string(folder_color) : .secondary)
                                    .frame(width: 44, height: 44)
                                    .background(
                                        folder_icon == icon
                                            ? color_from_string(folder_color).opacity(0.2)
                                            : Color.gray.opacity(0.1),
                                        in: RoundedRectangle(cornerRadius: 10)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Section("Color") {
                    HStack(spacing: 12) {
                        ForEach(available_colors, id: \.self) { color in
                            Button(action: { folder_color = color }) {
                                Circle()
                                    .fill(color_from_string(color))
                                    .frame(width: 36, height: 36)
                                    .overlay(
                                        Circle()
                                            .strokeBorder(Color.white, lineWidth: folder_color == color ? 3 : 0)
                                    )
                                    .shadow(color: folder_color == color ? color_from_string(color).opacity(0.5) : .clear, radius: 4)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 8)
                }

                // Preview
                Section("Preview") {
                    HStack(spacing: 12) {
                        Image(systemName: folder_icon)
                            .font(.title2)
                            .foregroundColor(color_from_string(folder_color))
                            .frame(width: 44, height: 44)
                            .background(color_from_string(folder_color).opacity(0.15), in: RoundedRectangle(cornerRadius: 10))

                        Text(folder_name.isEmpty ? "Folder Name" : folder_name)
                            .font(.headline)
                            .foregroundColor(folder_name.isEmpty ? .secondary : .primary)
                    }
                }
            }
            .navigationTitle(existing_folder == nil ? "New Folder" : "Edit Folder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        save_folder()
                        dismiss()
                    }
                    .disabled(folder_name.trimmingCharacters(in: .whitespaces).isEmpty)
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                if let folder = existing_folder {
                    folder_name = folder.folder_name
                    folder_icon = folder.folder_icon
                    folder_color = folder.folder_color
                }
            }
        }
    }

    private func save_folder() {
        if let existing = existing_folder {
            var updated = existing
            updated.folder_name = folder_name.trimmingCharacters(in: .whitespaces)
            updated.folder_icon = folder_icon
            updated.folder_color = folder_color
            memory_service.update_folder(updated)
        } else {
            let new_folder = MemoryFolder(
                folder_name: folder_name.trimmingCharacters(in: .whitespaces),
                folder_icon: folder_icon,
                folder_color: folder_color
            )
            memory_service.create_folder(new_folder)
        }
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
        case "cyan": return .cyan
        default: return .blue
        }
    }
}

// MARK: - Block Editor Sheet

struct BlockEditorSheet: View {
    @ObservedObject var memory_service: MemoryStorageService
    let folder: MemoryFolder
    let existing_block: MemoryBlock?
    @Environment(\.dismiss) private var dismiss

    @State private var block_title: String = ""
    @State private var block_content: String = ""

    private var estimated_tokens: Int {
        (block_title.count + block_content.count) / 4
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Title") {
                    TextField("e.g., My coding preferences", text: $block_title)
                }

                Section {
                    TextEditor(text: $block_content)
                        .frame(minHeight: 150)
                } header: {
                    Text("Content")
                } footer: {
                    HStack {
                        Text("This text will be included as context in your chats.")
                        Spacer()
                        Text("~\(estimated_tokens) tokens")
                            .monospacedDigit()
                    }
                }

                Section("Examples") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("• My name is John and I prefer Swift over Objective-C")
                        Text("• I work at Acme Corp as a senior engineer")
                        Text("• Always use camelCase for variables in my projects")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            }
            .navigationTitle(existing_block == nil ? "New Memory" : "Edit Memory")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        save_block()
                        dismiss()
                    }
                    .disabled(block_title.trimmingCharacters(in: .whitespaces).isEmpty ||
                             block_content.trimmingCharacters(in: .whitespaces).isEmpty)
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                if let block = existing_block {
                    block_title = block.block_title
                    block_content = block.block_content
                }
            }
        }
    }

    private func save_block() {
        if let existing = existing_block {
            var updated = existing
            updated.block_title = block_title.trimmingCharacters(in: .whitespaces)
            updated.block_content = block_content.trimmingCharacters(in: .whitespaces)
            updated.block_updated_timestamp = Date()
            memory_service.update_block(in: folder.folder_id, block: updated)
        } else {
            let new_block = MemoryBlock(
                block_title: block_title.trimmingCharacters(in: .whitespaces),
                block_content: block_content.trimmingCharacters(in: .whitespaces)
            )
            memory_service.add_block(to: folder.folder_id, block: new_block)
        }
    }
}

// MARK: - Identifiable Extensions for Sheets

extension MemoryFolder: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(folder_id)
    }
}

extension MemoryBlock: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(block_id)
    }
}

#Preview {
    NavigationStack {
        MemorySettingsView(memory_service: MemoryStorageService())
    }
}
