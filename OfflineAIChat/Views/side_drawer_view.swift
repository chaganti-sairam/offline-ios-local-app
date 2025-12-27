import SwiftUI

/// Side drawer that slides in from the left
struct SideDrawerView<Content: View>: View {
    @Binding var is_open: Bool
    let content: Content

    init(is_open: Binding<Bool>, @ViewBuilder content: () -> Content) {
        self._is_open = is_open
        self.content = content()
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Dimmed background
                if is_open {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                is_open = false
                            }
                        }
                        .transition(.opacity)
                }

                // Drawer content
                HStack(spacing: 0) {
                    content
                        .frame(width: min(geometry.size.width * 0.85, 320))
                        .background(.ultraThickMaterial)
                        .offset(x: is_open ? 0 : -min(geometry.size.width * 0.85, 320))

                    Spacer()
                }
            }
        }
        .animation(.easeInOut(duration: 0.25), value: is_open)
    }
}

/// Chat session list for side drawer
struct ChatSessionDrawerView: View {
    @ObservedObject var storage_service: ChatStorageService
    let current_session_id: UUID
    let on_new_chat: () -> Void
    let on_select_session: (ChatSessionModel) -> Void
    let on_close: () -> Void

    @State private var search_query: String = ""

    private var filtered_sessions: [ChatSessionModel] {
        if search_query.isEmpty {
            return storage_service.saved_sessions
        }
        return storage_service.saved_sessions.filter { session in
            session.display_title.localizedCaseInsensitiveContains(search_query) ||
            session.session_messages.contains { message in
                message.message_content.localizedCaseInsensitiveContains(search_query)
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            drawer_header

            Divider()

            // Search
            search_field

            // Sessions list
            sessions_list

            Divider()

            // New chat button at bottom
            new_chat_button
        }
    }

    private var drawer_header: some View {
        HStack {
            Text("Chats")
                .font(.title2.bold())

            Spacer()

            Button(action: on_close) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
                    .frame(width: 32, height: 32)
                    .background(Color(.systemGray5), in: Circle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }

    private var search_field: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
                .font(.subheadline)

            TextField("Search chats...", text: $search_query)
                .font(.subheadline)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
    }

    private var sessions_list: some View {
        ScrollView {
            LazyVStack(spacing: 2) {
                ForEach(filtered_sessions) { session in
                    session_row(session: session)
                }

                if filtered_sessions.isEmpty {
                    empty_state
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
    }

    private func session_row(session: ChatSessionModel) -> some View {
        let is_current = session.session_id == current_session_id

        return Button(action: {
            on_select_session(session)
            on_close()
        }) {
            HStack(spacing: 12) {
                // Icon
                Image(systemName: is_current ? "bubble.left.fill" : "bubble.left")
                    .font(.system(size: 16))
                    .foregroundColor(is_current ? .blue : .secondary)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 3) {
                    Text(session.display_title)
                        .font(.subheadline.weight(is_current ? .semibold : .regular))
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    HStack(spacing: 6) {
                        Text(session.session_last_updated_timestamp.formatted_relative())
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text("•")
                            .foregroundColor(.secondary)
                            .font(.caption)

                        Text("\(session.message_count) messages")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                if is_current {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(is_current ? Color.blue.opacity(0.1) : Color.clear)
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }

    private var empty_state: some View {
        VStack(spacing: 12) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 40))
                .foregroundColor(.secondary.opacity(0.5))

            Text(search_query.isEmpty ? "No chats yet" : "No matching chats")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private var new_chat_button: some View {
        Button(action: {
            on_new_chat()
            on_close()
        }) {
            HStack(spacing: 10) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 20))

                Text("New Chat")
                    .font(.headline)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                LinearGradient(
                    colors: [.blue, .purple],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
        }
        .padding(16)
    }
}

// MARK: - Date Formatting Extension

extension Date {
    func formatted_relative() -> String {
        let calendar = Calendar.current
        let now = Date()

        if calendar.isDateInToday(self) {
            return "Today"
        } else if calendar.isDateInYesterday(self) {
            return "Yesterday"
        } else if let days_ago = calendar.dateComponents([.day], from: self, to: now).day, days_ago < 7 {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            return formatter.string(from: self)
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            return formatter.string(from: self)
        }
    }
}

#Preview {
    SideDrawerView(is_open: .constant(true)) {
        ChatSessionDrawerView(
            storage_service: ChatStorageService(),
            current_session_id: UUID(),
            on_new_chat: {},
            on_select_session: { _ in },
            on_close: {}
        )
    }
}
