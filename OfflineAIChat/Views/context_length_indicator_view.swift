import SwiftUI

/// Shows context length usage as a progress indicator
struct ContextLengthIndicatorView: View {
    let current_token_count: Int
    let max_token_count: Int
    let is_compact: Bool

    init(
        current_token_count: Int,
        max_token_count: Int,
        is_compact: Bool = false
    ) {
        self.current_token_count = current_token_count
        self.max_token_count = max_token_count
        self.is_compact = is_compact
    }

    private var usage_percentage: Double {
        guard max_token_count > 0 else { return 0 }
        return min(1.0, Double(current_token_count) / Double(max_token_count))
    }

    private var remaining_tokens: Int {
        max(0, max_token_count - current_token_count)
    }

    private var usage_color: Color {
        if usage_percentage > 0.9 {
            return .red
        } else if usage_percentage > 0.75 {
            return .orange
        } else if usage_percentage > 0.5 {
            return .yellow
        } else {
            return .green
        }
    }

    private var usage_text: String {
        if current_token_count >= 1000 {
            return String(format: "%.1fK", Double(current_token_count) / 1000)
        }
        return "\(current_token_count)"
    }

    private var max_text: String {
        if max_token_count >= 1000 {
            return String(format: "%.0fK", Double(max_token_count) / 1000)
        }
        return "\(max_token_count)"
    }

    var body: some View {
        if is_compact {
            compact_view
        } else {
            expanded_view
        }
    }

    // MARK: - Compact View (for header)

    private var compact_view: some View {
        HStack(spacing: 6) {
            // Circular progress
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 2)

                Circle()
                    .trim(from: 0, to: usage_percentage)
                    .stroke(usage_color, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
            .frame(width: 14, height: 14)

            Text("\(Int(usage_percentage * 100))%")
                .font(.caption2.monospacedDigit())
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Expanded View (for settings/details)

    private var expanded_view: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Context Usage")
                    .font(.caption.weight(.medium))
                    .foregroundColor(.secondary)

                Spacer()

                Text("\(usage_text) / \(max_text) tokens")
                    .font(.caption.monospacedDigit())
                    .foregroundColor(.secondary)
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    Capsule()
                        .fill(Color.gray.opacity(0.2))

                    // Fill
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [usage_color.opacity(0.8), usage_color],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * usage_percentage)
                        .animation(.easeInOut(duration: 0.3), value: usage_percentage)
                }
            }
            .frame(height: 6)

            // Warning text if nearing limit
            if usage_percentage > 0.75 {
                HStack(spacing: 4) {
                    Image(systemName: usage_percentage > 0.9 ? "exclamationmark.triangle.fill" : "info.circle.fill")
                        .font(.caption2)

                    Text(usage_percentage > 0.9 ? "Context nearly full" : "\(remaining_tokens) tokens remaining")
                        .font(.caption2)
                }
                .foregroundColor(usage_color)
            }
        }
    }
}

// MARK: - Token Counter Helper

struct TokenCounter {
    /// Estimates token count for a string (rough approximation: 1 token ≈ 4 characters)
    static func estimate_tokens(for text: String) -> Int {
        max(1, text.count / 4)
    }

    /// Estimates total tokens for an array of chat messages
    static func estimate_conversation_tokens(messages: [ChatMessageModel]) -> Int {
        messages.reduce(0) { total, message in
            total + estimate_tokens(for: message.message_content) + 4 // +4 for role markers
        }
    }
}

#Preview("Compact") {
    ContextLengthIndicatorView(
        current_token_count: 1500,
        max_token_count: 4096,
        is_compact: true
    )
    .padding()
}

#Preview("Expanded - Low Usage") {
    ContextLengthIndicatorView(
        current_token_count: 500,
        max_token_count: 4096
    )
    .padding()
}

#Preview("Expanded - High Usage") {
    ContextLengthIndicatorView(
        current_token_count: 3800,
        max_token_count: 4096
    )
    .padding()
}
