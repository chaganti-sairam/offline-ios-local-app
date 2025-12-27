import SwiftUI

struct ChatConversationView: View {
    @ObservedObject var view_model: ChatConversationViewModel
    @ObservedObject var download_service: ModelDownloadService
    @ObservedObject var inference_service: NexaInferenceService
    @ObservedObject var storage_service: ChatStorageService
    @ObservedObject var memory_service: MemoryStorageService

    @State private var show_settings: Bool = false
    @State private var show_session_drawer: Bool = false
    @State private var show_export_sheet: Bool = false
    @State private var show_memory_toggle: Bool = false

    private let bottom_anchor_identifier = "bottom_anchor"

    var body: some View {
        ZStack {
            // Main content
            VStack(spacing: 0) {
                // Custom header with glass effect
                custom_header_view

                // Status banners
                if let error_message = view_model.error_message {
                    error_banner_view(error_message: error_message)
                } else {
                    model_status_banner
                }

                // Chat content
                chat_messages_list_view

                Divider()

                input_area_view
            }
            .background(Color(.systemBackground))

            // Side drawer overlay
            SideDrawerView(is_open: $show_session_drawer) {
                ChatSessionDrawerView(
                    storage_service: storage_service,
                    current_session_id: view_model.current_chat_session.session_id,
                    on_new_chat: {
                        view_model.start_new_session()
                    },
                    on_select_session: { session in
                        view_model.load_session(session)
                    },
                    on_close: {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            show_session_drawer = false
                        }
                    }
                )
            }
        }
        .sheet(isPresented: $show_settings) {
            ModelSettingsView(
                download_service: download_service,
                inference_service: inference_service,
                memory_service: memory_service
            )
        }
        .sheet(isPresented: $show_export_sheet) {
            export_sheet_view
        }
        .sheet(isPresented: $show_memory_toggle) {
            MemoryQuickToggleView(memory_service: memory_service)
        }
        .task {
            await load_active_model_if_needed()
        }
        .onChange(of: download_service.active_model) { _, new_model in
            if let model = new_model {
                view_model.update_max_context_tokens(model_context_length: model.context_length)
                Task {
                    try? await inference_service.load_model(model)
                }
            }
        }
    }

    // MARK: - Custom Header

    private var custom_header_view: some View {
        HStack(spacing: 16) {
            // Left: Hamburger menu for chat list (side drawer)
            Button(action: {
                withAnimation(.easeInOut(duration: 0.25)) {
                    show_session_drawer = true
                }
            }) {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.primary)
                    .frame(width: 40, height: 40)
                    .background(.ultraThinMaterial, in: Circle())
            }

            // Center: Title and context indicator
            VStack(spacing: 2) {
                Text(view_model.current_chat_session.display_title)
                    .font(.headline)
                    .lineLimit(1)

                if !view_model.current_chat_session.is_empty {
                    ContextLengthIndicatorView(
                        current_token_count: view_model.current_context_tokens,
                        max_token_count: view_model.max_context_tokens,
                        is_compact: true
                    )
                }
            }
            .frame(maxWidth: .infinity)

            // Right: New chat + Menu
            HStack(spacing: 8) {
                // New chat button
                Button(action: {
                    view_model.start_new_session()
                }) {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.primary)
                        .frame(width: 40, height: 40)
                        .background(.ultraThinMaterial, in: Circle())
                }

                // More options menu
                Menu {
                    Button(action: {
                        show_settings = true
                    }) {
                        Label("Settings", systemImage: "gearshape")
                    }

                    if !view_model.current_chat_session.is_empty {
                        Divider()

                        Button(action: {
                            show_export_sheet = true
                        }) {
                            Label("Export Chat", systemImage: "square.and.arrow.up")
                        }

                        Button(role: .destructive, action: {
                            view_model.clear_conversation()
                        }) {
                            Label("Delete Chat", systemImage: "trash")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.primary)
                        .frame(width: 40, height: 40)
                        .background(.ultraThinMaterial, in: Circle())
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }

    // MARK: - Model Status Banner

    @ViewBuilder
    private var model_status_banner: some View {
        if download_service.active_model == nil {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text("No model downloaded")
                    .font(.subheadline)
                Spacer()
                Button("Settings") {
                    show_settings = true
                }
                .font(.subheadline.bold())
                .foregroundColor(.orange)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.orange.opacity(0.1))
        } else if case .loading = inference_service.loading_state {
            HStack(spacing: 8) {
                ProgressView()
                    .scaleEffect(0.8)
                Text("Loading \(download_service.active_model?.display_name ?? "model")...")
                    .font(.subheadline)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial)
        } else if case .error(let error) = inference_service.loading_state {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundColor(.red)
                Text(error)
                    .font(.subheadline)
                    .lineLimit(1)
                Spacer()
                Button("Retry") {
                    Task { await load_active_model_if_needed() }
                }
                .font(.subheadline.bold())
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.red.opacity(0.1))
        } else if inference_service.loading_state.is_ready {
            HStack(spacing: 6) {
                Circle()
                    .fill(Color.green)
                    .frame(width: 8, height: 8)
                Text(inference_service.loaded_model?.display_name ?? "Model Ready")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()

                // Show memory indicator if memories are enabled
                if memory_service.enabled_memory_block_count > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "brain.head.profile")
                            .font(.caption2)
                        Text("\(memory_service.enabled_memory_block_count)")
                            .font(.caption2)
                    }
                    .foregroundColor(.purple)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.purple.opacity(0.1), in: Capsule())
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial)
        }
    }

    private func load_active_model_if_needed() async {
        if let model = download_service.active_model,
           inference_service.loaded_model != model {
            view_model.update_max_context_tokens(model_context_length: model.context_length)
            try? await inference_service.load_model(model)
        }
    }

    // MARK: - Chat Messages List

    private var chat_messages_list_view: some View {
        ScrollViewReader { scroll_view_proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    if view_model.current_chat_session.is_empty && !view_model.is_assistant_responding {
                        AnimatedEmptyStateView()
                    }

                    ForEach(view_model.current_chat_session.session_messages) { message in
                        ChatMessageRowView(
                            message: message,
                            on_regenerate: message == view_model.current_chat_session.last_message && message.message_role == .assistant ? {
                                Task {
                                    await view_model.regenerate_last_response()
                                }
                            } : nil
                        )
                        .id(message.message_id)
                    }

                    if view_model.is_assistant_responding {
                        streaming_response_bubble_view
                    }

                    Color.clear
                        .frame(height: 1)
                        .id(bottom_anchor_identifier)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .onChange(of: view_model.current_chat_session.session_messages.count) { _, _ in
                scroll_to_bottom(proxy: scroll_view_proxy)
            }
            .onChange(of: view_model.current_assistant_response) { _, new_response in
                if !new_response.isEmpty {
                    scroll_to_bottom(proxy: scroll_view_proxy)
                }
            }
            .onChange(of: view_model.is_assistant_responding) { _, _ in
                scroll_to_bottom(proxy: scroll_view_proxy)
            }
        }
    }

    // MARK: - Streaming Response Bubble

    private var streaming_response_bubble_view: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                if view_model.current_assistant_response.isEmpty {
                    HStack(spacing: 6) {
                        ForEach(0..<3, id: \.self) { index in
                            Circle()
                                .fill(Color.gray)
                                .frame(width: 8, height: 8)
                                .opacity(0.6)
                                .animation(
                                    .easeInOut(duration: 0.6)
                                        .repeatForever(autoreverses: true)
                                        .delay(Double(index) * 0.2),
                                    value: view_model.is_assistant_responding
                                )
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 14)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                } else {
                    Text(view_model.current_assistant_response)
                        .foregroundColor(.primary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                        .textSelection(.enabled)
                }

                HStack(spacing: 4) {
                    ProgressView()
                        .scaleEffect(0.7)

                    Text(view_model.current_assistant_response.isEmpty ? "Thinking..." : "Generating...")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.leading, 8)
            }

            Spacer()
        }
    }

    // MARK: - Input Area

    private var input_area_view: some View {
        HStack(alignment: .center, spacing: 10) {
            // Memory toggle button - center aligned
            Button(action: {
                show_memory_toggle = true
            }) {
                ZStack {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 18))
                        .foregroundColor(memory_service.enabled_memory_block_count > 0 ? .purple : .secondary)

                    // Badge for active memories
                    if memory_service.enabled_memory_block_count > 0 {
                        Text("\(memory_service.enabled_memory_block_count)")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 14, height: 14)
                            .background(Color.purple, in: Circle())
                            .offset(x: 10, y: -10)
                    }
                }
                .frame(width: 36, height: 36)
                .background(.ultraThinMaterial, in: Circle())
            }

            TextField("Type a message...", text: $view_model.user_input_text, axis: .vertical)
                .lineLimit(1...5)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
                .disabled(view_model.is_assistant_responding || !inference_service.loading_state.is_ready)
                .onSubmit {
                    if view_model.can_send_message() {
                        Task {
                            await view_model.send_user_message()
                        }
                    }
                }

            // Send or Stop button
            if view_model.is_assistant_responding {
                Button(action: {
                    view_model.stop_generation()
                }) {
                    Image(systemName: "stop.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.red)
                }
            } else {
                Button(action: {
                    Task {
                        await view_model.send_user_message()
                    }
                }) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(
                            view_model.can_send_message()
                                ? LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                                : LinearGradient(colors: [.gray], startPoint: .top, endPoint: .bottom)
                        )
                }
                .disabled(!view_model.can_send_message())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Error Banner

    private func error_banner_view(error_message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.white)

            Text(error_message)
                .font(.subheadline)
                .foregroundColor(.white)
                .lineLimit(2)

            Spacer()

            Button(action: {
                view_model.error_message = nil
            }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.red)
    }

    // MARK: - Export Sheet

    private var export_sheet_view: some View {
        NavigationView {
            VStack {
                ScrollView {
                    Text(view_model.export_conversation())
                        .font(.system(.body, design: .monospaced))
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                .padding()

                HStack(spacing: 16) {
                    Button(action: {
                        UIPasteboard.general.string = view_model.export_conversation()
                        show_export_sheet = false
                    }) {
                        Label("Copy", systemImage: "doc.on.doc")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)

                    Button(action: {
                        share_export()
                    }) {
                        Label("Share", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            }
            .navigationTitle("Export Chat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        show_export_sheet = false
                    }
                }
            }
        }
    }

    // MARK: - Helper Functions

    private func scroll_to_bottom(proxy: ScrollViewProxy) {
        withAnimation(.easeOut(duration: 0.2)) {
            proxy.scrollTo(bottom_anchor_identifier, anchor: .bottom)
        }
    }

    private func share_export() {
        let text = view_model.export_conversation()

        guard let window_scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root_controller = window_scene.windows.first?.rootViewController else {
            return
        }

        let activity_controller = UIActivityViewController(
            activityItems: [text],
            applicationActivities: nil
        )

        if let popover = activity_controller.popoverPresentationController {
            popover.sourceView = root_controller.view
            popover.sourceRect = CGRect(x: root_controller.view.bounds.midX, y: root_controller.view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }

        root_controller.present(activity_controller, animated: true)
        show_export_sheet = false
    }
}

// MARK: - Preview

#Preview {
    let inference_service = NexaInferenceService()
    let download_service = ModelDownloadService()
    let storage_service = ChatStorageService()
    let memory_service = MemoryStorageService()
    ChatConversationView(
        view_model: ChatConversationViewModel(inference_service: inference_service, storage_service: storage_service),
        download_service: download_service,
        inference_service: inference_service,
        storage_service: storage_service,
        memory_service: memory_service
    )
}
