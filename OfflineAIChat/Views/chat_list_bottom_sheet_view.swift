import SwiftUI

/// Bottom sheet for chat session list with glass effect
struct ChatListBottomSheetView: View {
    @ObservedObject var storage_service: ChatStorageService
    @Binding var selected_session_id: UUID?
    let current_session_id: UUID
    let on_new_chat: () -> Void
    let on_select_session: (ChatSessionModel) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var session_to_delete: ChatSessionModel?
    @State private var show_delete_confirmation = false
    @State private var search_text: String = ""

    private var filtered_sessions: [ChatSessionModel] {
        if search_text.isEmpty {
            return storage_service.saved_sessions
        }
        return storage_service.saved_sessions.filter { session in
            session.display_title.localizedCaseInsensitiveContains(search_text)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header with new chat button
                header_section

                Divider()
                    .padding(.horizontal)

                // Chat list
                if storage_service.saved_sessions.isEmpty {
                    empty_state_section
                } else {
                    chat_list_section
                }
            }
            .background(.ultraThinMaterial)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Chats")
                        .font(.headline)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.medium)
                }
            }
            .confirmationDialog(
                "Delete Chat",
                isPresented: $show_delete_confirmation,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    if let session = session_to_delete {
                        delete_session(session)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This chat will be permanently deleted.")
            }
        }
    }

    // MARK: - Header Section

    private var header_section: some View {
        VStack(spacing: 16) {
            // New chat button
            Button(action: {
                on_new_chat()
                dismiss()
            }) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 44, height: 44)

                        Image(systemName: "plus")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("New Chat")
                            .font(.headline)
                            .foregroundColor(.primary)

                        Text("Start a fresh conversation")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.secondary)
                }
                .padding(12)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)

            // Search bar (only show if there are sessions)
            if !storage_service.saved_sessions.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)

                    TextField("Search chats...", text: $search_text)
                        .textFieldStyle(.plain)

                    if !search_text.isEmpty {
                        Button(action: { search_text = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(10)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding()
    }

    // MARK: - Empty State

    private var empty_state_section: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 48))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.gray.opacity(0.5), .gray.opacity(0.3)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            Text("No saved chats")
                .font(.title3.weight(.medium))
                .foregroundColor(.secondary)

            Text("Your conversations will appear here")
                .font(.subheadline)
                .foregroundColor(.secondary.opacity(0.8))

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Chat List

    private var chat_list_section: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                // Recent section header
                if !filtered_sessions.isEmpty {
                    HStack {
                        Text("Recent")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(filtered_sessions.count) chats")
                            .font(.caption)
                            .foregroundColor(.secondary.opacity(0.7))
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                }

                ForEach(filtered_sessions) { session in
                    session_row(session: session)
                        .padding(.horizontal)
                }
            }
            .padding(.bottom, 20)
        }
    }

    // MARK: - Session Row

    private func session_row(session: ChatSessionModel) -> some View {
        let is_current = session.session_id == current_session_id

        return Button(action: {
            on_select_session(session)
            dismiss()
        }) {
            HStack(spacing: 14) {
                // Avatar/Icon
                ZStack {
                    Circle()
                        .fill(is_current ? Color.blue.opacity(0.15) : Color.gray.opacity(0.1))
                        .frame(width: 44, height: 44)

                    Image(systemName: is_current ? "bubble.left.and.bubble.right.fill" : "bubble.left.and.bubble.right")
                        .font(.system(size: 18))
                        .foregroundColor(is_current ? .blue : .secondary)
                }

                // Content
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(session.display_title)
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.primary)
                            .lineLimit(1)

                        Spacer()

                        Text(format_relative_date(session.session_last_updated_timestamp))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    HStack(spacing: 6) {
                        Text("\(session.message_count) messages")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        if is_current {
                            Text("•")
                                .foregroundColor(.blue)
                            Text("Current")
                                .font(.caption.weight(.medium))
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(is_current ? Color.blue.opacity(0.08) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(is_current ? Color.blue.opacity(0.2) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                on_select_session(session)
                dismiss()
            } label: {
                Label("Open", systemImage: "bubble.left.and.bubble.right")
            }

            Divider()

            Button(role: .destructive) {
                session_to_delete = session
                show_delete_confirmation = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                session_to_delete = session
                show_delete_confirmation = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    // MARK: - Helper Functions

    private func delete_session(_ session: ChatSessionModel) {
        storage_service.delete_session(session_id: session.session_id)
        if current_session_id == session.session_id {
            on_new_chat()
        }
    }

    private func format_relative_date(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()

        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return formatter.string(from: date)
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else if let days_ago = calendar.dateComponents([.day], from: date, to: now).day, days_ago < 7 {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            return formatter.string(from: date)
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            return formatter.string(from: date)
        }
    }
}

#Preview {
    Text("Preview")
        .sheet(isPresented: .constant(true)) {
            ChatListBottomSheetView(
                storage_service: ChatStorageService(),
                selected_session_id: .constant(nil),
                current_session_id: UUID(),
                on_new_chat: {},
                on_select_session: { _ in }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
}
