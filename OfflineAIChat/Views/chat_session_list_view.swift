import SwiftUI

struct ChatSessionListView: View {
    @ObservedObject var storage_service: ChatStorageService
    @Binding var selected_session_id: UUID?
    let on_new_chat: () -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var session_to_delete: ChatSessionModel?
    @State private var show_delete_confirmation = false

    var body: some View {
        NavigationView {
            List {
                // New chat button at top
                Section {
                    Button(action: {
                        on_new_chat()
                        dismiss()
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundColor(.blue)

                            Text("New Chat")
                                .font(.headline)
                                .foregroundColor(.primary)

                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                }

                // Saved sessions
                if storage_service.saved_sessions.isEmpty {
                    Section {
                        VStack(spacing: 12) {
                            Image(systemName: "bubble.left.and.bubble.right")
                                .font(.largeTitle)
                                .foregroundColor(.secondary)

                            Text("No saved chats yet")
                                .font(.headline)
                                .foregroundColor(.secondary)

                            Text("Your conversations will appear here")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    }
                } else {
                    Section {
                        ForEach(storage_service.saved_sessions) { session in
                            session_row_view(session: session)
                        }
                        .onDelete(perform: delete_sessions)
                    } header: {
                        Text("Recent Chats")
                    }
                }
            }
            .navigationTitle("Chats")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .confirmationDialog(
                "Delete Chat",
                isPresented: $show_delete_confirmation,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    if let session = session_to_delete {
                        storage_service.delete_session(session_id: session.session_id)
                        if selected_session_id == session.session_id {
                            on_new_chat()
                        }
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This chat will be permanently deleted.")
            }
        }
    }

    // MARK: - Session Row

    private func session_row_view(session: ChatSessionModel) -> some View {
        Button(action: {
            selected_session_id = session.session_id
            dismiss()
        }) {
            HStack(spacing: 12) {
                // Chat icon
                Image(systemName: selected_session_id == session.session_id ? "bubble.left.and.bubble.right.fill" : "bubble.left.and.bubble.right")
                    .font(.title3)
                    .foregroundColor(selected_session_id == session.session_id ? .blue : .secondary)
                    .frame(width: 28)

                // Session info
                VStack(alignment: .leading, spacing: 4) {
                    Text(session.display_title)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    HStack(spacing: 8) {
                        Text(storage_service.session_formatted_date(session))
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text("•")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text("\(session.message_count) messages")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // Current indicator
                if selected_session_id == session.session_id {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            .padding(.vertical, 4)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                session_to_delete = session
                show_delete_confirmation = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .contextMenu {
            Button {
                selected_session_id = session.session_id
                dismiss()
            } label: {
                Label("Open", systemImage: "bubble.left.and.bubble.right")
            }

            Button(role: .destructive) {
                session_to_delete = session
                show_delete_confirmation = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    // MARK: - Delete Handler

    private func delete_sessions(at offsets: IndexSet) {
        for index in offsets {
            let session = storage_service.saved_sessions[index]
            storage_service.delete_session(session_id: session.session_id)
            if selected_session_id == session.session_id {
                on_new_chat()
            }
        }
    }
}

#Preview {
    ChatSessionListView(
        storage_service: ChatStorageService(),
        selected_session_id: .constant(nil),
        on_new_chat: {}
    )
}
