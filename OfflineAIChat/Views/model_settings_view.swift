import SwiftUI

struct ModelSettingsView: View {
    @ObservedObject var download_service: ModelDownloadService
    var inference_service: NexaInferenceService?
    @ObservedObject var memory_service: MemoryStorageService
    @Environment(\.dismiss) private var dismiss

    @State private var selected_tab: SettingsTab = .models
    @State private var show_unload_confirmation: Bool = false
    @State private var model_to_unload: AvailableModel?

    enum SettingsTab: String, CaseIterable {
        case models = "Models"
        case memories = "Memories"

        var icon: String {
            switch self {
            case .models: return "cpu"
            case .memories: return "brain.head.profile"
            }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Custom tab picker
                tab_picker

                Divider()

                // Tab content
                switch selected_tab {
                case .models:
                    models_list_view
                case .memories:
                    MemorySettingsView(memory_service: memory_service)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.medium)
                }
            }
            .alert("Unload Model?", isPresented: $show_unload_confirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Unload", role: .destructive) {
                    inference_service?.unload_model()
                }
            } message: {
                Text("The model will be removed from memory. You can reload it anytime.")
            }
        }
    }

    // MARK: - Tab Picker

    private var tab_picker: some View {
        HStack(spacing: 0) {
            ForEach(SettingsTab.allCases, id: \.self) { tab in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selected_tab = tab
                    }
                }) {
                    VStack(spacing: 6) {
                        HStack(spacing: 6) {
                            Image(systemName: tab.icon)
                                .font(.subheadline)

                            Text(tab.rawValue)
                                .font(.subheadline.weight(.medium))
                        }
                        .foregroundColor(selected_tab == tab ? .primary : .secondary)

                        // Indicator
                        Rectangle()
                            .fill(selected_tab == tab ? Color.blue : Color.clear)
                            .frame(height: 2)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.top, 8)
        .background(.ultraThinMaterial)
    }

    // MARK: - Resource Stats

    private var resource_stats_section: some View {
        Section {
            HStack(spacing: 0) {
                // Memory usage
                stat_card(
                    icon: "memorychip",
                    color: .blue,
                    title: "Memory",
                    value: format_memory_usage(),
                    subtitle: inference_service?.loaded_model != nil ? "Model loaded" : "No model"
                )

                Divider()
                    .frame(height: 50)

                // Storage used
                stat_card(
                    icon: "internaldrive",
                    color: .purple,
                    title: "Storage",
                    value: calculate_storage_used(),
                    subtitle: "\(count_downloaded_models()) models"
                )

                Divider()
                    .frame(height: 50)

                // Model status
                stat_card(
                    icon: "cpu",
                    color: inference_service?.loaded_model != nil ? .green : .orange,
                    title: "Status",
                    value: inference_service?.loaded_model != nil ? "Ready" : "Idle",
                    subtitle: inference_service?.loaded_model?.display_name ?? "No model"
                )
            }
        }
        .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
    }

    private func stat_card(icon: String, color: Color, title: String, value: String, subtitle: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)

            Text(value)
                .font(.system(size: 15, weight: .semibold).monospacedDigit())

            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }

    private func format_memory_usage() -> String {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }

        if result == KERN_SUCCESS {
            let bytes = Int64(info.resident_size)
            let formatter = ByteCountFormatter()
            formatter.countStyle = .memory
            formatter.allowedUnits = [.useMB, .useGB]
            return formatter.string(fromByteCount: bytes)
        }
        return "-- MB"
    }

    // MARK: - Models List

    private var models_list_view: some View {
        List {
            // Resource stats section
            resource_stats_section

            // Active/Loaded model section
            if let loaded = inference_service?.loaded_model {
                Section {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(loaded.display_name)
                                .font(.headline)

                            HStack(spacing: 8) {
                                Label("\(loaded.context_length / 1000)K context", systemImage: "text.alignleft")
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                Label(loaded.ram_usage_formatted, systemImage: "memorychip")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        Spacer()
                        Button("Unload") {
                            show_unload_confirmation = true
                        }
                        .foregroundColor(.red)
                        .font(.subheadline.weight(.medium))
                    }
                    .padding(.vertical, 4)
                } header: {
                    Label("Active Model", systemImage: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }

            // Models by category
            ForEach(ModelCategory.allCases, id: \.self) { category in
                let models_in_category = AvailableModel.allCases.filter { $0.category == category }

                Section {
                    ForEach(models_in_category) { model in
                        ModelRowView(
                            model: model,
                            download_service: download_service,
                            inference_service: inference_service,
                            on_unload_with_confirmation: {
                                show_unload_confirmation = true
                            }
                        )
                    }
                } header: {
                    HStack {
                        Text(category.rawValue)
                        Spacer()
                        Text(category.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

        }
    }

    // MARK: - Helpers

    private func calculate_storage_used() -> String {
        var total_bytes: Int64 = 0
        for model in AvailableModel.allCases where model.is_downloaded {
            if let attrs = try? FileManager.default.attributesOfItem(atPath: model.local_file_url.path),
               let size = attrs[.size] as? Int64 {
                total_bytes += size
            }
        }
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: total_bytes)
    }

    private func count_downloaded_models() -> Int {
        AvailableModel.allCases.filter { $0.is_downloaded }.count
    }
}

// MARK: - Model Row View

struct ModelRowView: View {
    let model: AvailableModel
    @ObservedObject var download_service: ModelDownloadService
    var inference_service: NexaInferenceService?
    var on_unload_with_confirmation: (() -> Void)?
    @State private var is_downloading = false

    private var is_highlighted: Bool {
        inference_service?.loaded_model == model || download_service.active_model == model
    }

    var body: some View {
        HStack(spacing: 12) {
            // Status icon
            status_icon

            // Model info
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(model.display_name)
                        .font(.headline)

                    if inference_service?.loaded_model == model {
                        Text("Loaded")
                            .font(.caption2.weight(.semibold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.15))
                            .foregroundColor(.green)
                            .cornerRadius(4)
                    } else if download_service.active_model == model {
                        Text("Selected")
                            .font(.caption2.weight(.medium))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.15))
                            .foregroundColor(.blue)
                            .cornerRadius(4)
                    }
                }

                HStack(spacing: 12) {
                    Text("\(model.estimated_size_mb) MB")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("•")
                        .foregroundColor(.secondary)

                    Text("\(model.context_length / 1000)K ctx")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("•")
                        .foregroundColor(.secondary)

                    Text(model.ram_usage_formatted)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Action button
            action_button
        }
        .padding(.vertical, 8)
        .padding(.horizontal, is_highlighted ? 10 : 0)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    is_highlighted
                        ? LinearGradient(
                            colors: [Color.blue.opacity(0.06), Color.purple.opacity(0.06)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                          )
                        : LinearGradient(colors: [.clear], startPoint: .top, endPoint: .bottom)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    is_highlighted
                        ? LinearGradient(
                            colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                          )
                        : LinearGradient(colors: [.clear], startPoint: .top, endPoint: .bottom),
                    lineWidth: 1.5
                )
        )
        .contentShape(Rectangle())
        .onTapGesture {
            if model.is_downloaded {
                download_service.set_active_model(model)
            }
        }
    }

    @ViewBuilder
    private var status_icon: some View {
        let state = download_service.download_states[model] ?? .not_downloaded

        switch state {
        case .not_downloaded:
            Image(systemName: "arrow.down.circle")
                .font(.title2)
                .foregroundColor(.blue)

        case .downloading(let progress):
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 3)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                Text("\(Int(progress * 100))")
                    .font(.caption2.bold())
            }
            .frame(width: 32, height: 32)

        case .downloaded:
            Image(systemName: "checkmark.circle.fill")
                .font(.title2)
                .foregroundColor(.green)

        case .failed:
            Image(systemName: "exclamationmark.circle.fill")
                .font(.title2)
                .foregroundColor(.red)
        }
    }

    @ViewBuilder
    private var action_button: some View {
        let state = download_service.download_states[model] ?? .not_downloaded

        switch state {
        case .not_downloaded, .failed:
            Button {
                start_download()
            } label: {
                Text("Download")
                    .font(.subheadline.weight(.medium))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .buttonStyle(.plain)

        case .downloading:
            Button {
                download_service.cancel_download(model: model)
            } label: {
                Text("Cancel")
                    .font(.subheadline.weight(.medium))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.red.opacity(0.1))
                    .foregroundColor(.red)
                    .cornerRadius(10)
            }
            .buttonStyle(.plain)

        case .downloaded:
            let is_loaded = inference_service?.loaded_model == model
            let is_active = download_service.active_model == model

            Menu {
                // Load/Unload options
                if is_loaded {
                    Button {
                        on_unload_with_confirmation?()
                    } label: {
                        Label("Unload from Memory", systemImage: "arrow.down.to.line")
                    }
                } else if is_active {
                    Button {
                        Task {
                            try? await inference_service?.load_model(model)
                        }
                    } label: {
                        Label("Load into Memory", systemImage: "arrow.up.to.line")
                    }
                }

                if !is_active {
                    Button {
                        download_service.set_active_model(model)
                    } label: {
                        Label("Set Active", systemImage: "checkmark.circle")
                    }
                }

                Divider()

                Button(role: .destructive) {
                    download_service.delete_model(model: model)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.secondary, Color.gray.opacity(0.15))
            }
        }
    }

    private func start_download() {
        Task {
            do {
                _ = try await download_service.start_download(model: model)
            } catch {
                print("Download failed: \(error)")
            }
        }
    }
}

#Preview {
    ModelSettingsView(
        download_service: ModelDownloadService(),
        inference_service: nil,
        memory_service: MemoryStorageService()
    )
}
