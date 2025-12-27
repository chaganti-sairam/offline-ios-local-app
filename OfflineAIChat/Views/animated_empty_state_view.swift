import SwiftUI

/// Animated colorful empty state for new chat sessions
struct AnimatedEmptyStateView: View {
    @State private var gradient_rotation: Double = 0
    @State private var icon_scale: CGFloat = 1.0
    @State private var particles_visible: Bool = false

    private let gradient_colors: [Color] = [
        .purple.opacity(0.6),
        .blue.opacity(0.6),
        .cyan.opacity(0.6),
        .mint.opacity(0.6),
        .green.opacity(0.6)
    ]

    var body: some View {
        VStack(spacing: 24) {
            // Animated gradient orb with particles
            ZStack {
                // Background glow
                Circle()
                    .fill(
                        AngularGradient(
                            colors: gradient_colors,
                            center: .center,
                            startAngle: .degrees(gradient_rotation),
                            endAngle: .degrees(gradient_rotation + 360)
                        )
                    )
                    .frame(width: 120, height: 120)
                    .blur(radius: 30)
                    .opacity(0.5)

                // Floating particles
                ForEach(0..<6, id: \.self) { index in
                    particle_view(index: index)
                }

                // Main icon
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 80, height: 80)

                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 36, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.purple, .blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .scaleEffect(icon_scale)
            }
            .frame(height: 140)

            // Welcome text
            VStack(spacing: 12) {
                Text("Start a conversation")
                    .font(.title2.weight(.semibold))
                    .foregroundColor(.primary)

                Text("Your AI assistant runs entirely on-device.\nNo internet. No data shared. Complete privacy.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 32)

            // Feature pills
            HStack(spacing: 12) {
                feature_pill(icon: "lock.shield.fill", text: "Private")
                feature_pill(icon: "bolt.fill", text: "Fast")
                feature_pill(icon: "wifi.slash", text: "Offline")
            }
            .padding(.top, 8)
        }
        .padding(.vertical, 40)
        .onAppear {
            start_animations()
        }
    }

    // MARK: - Particle View

    private func particle_view(index: Int) -> some View {
        let angle = Double(index) * 60 + gradient_rotation * 0.5
        let radius: CGFloat = 55
        let x = cos(angle * .pi / 180) * radius
        let y = sin(angle * .pi / 180) * radius

        return Circle()
            .fill(gradient_colors[index % gradient_colors.count])
            .frame(width: 8, height: 8)
            .blur(radius: 2)
            .offset(x: x, y: y)
            .opacity(particles_visible ? 0.8 : 0)
    }

    // MARK: - Feature Pill

    private func feature_pill(icon: String, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption.weight(.semibold))
            Text(text)
                .font(.caption.weight(.medium))
        }
        .foregroundColor(.secondary)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: Capsule())
    }

    // MARK: - Animations

    private func start_animations() {
        // Continuous gradient rotation
        withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
            gradient_rotation = 360
        }

        // Icon pulse
        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
            icon_scale = 1.05
        }

        // Particles fade in
        withAnimation(.easeOut(duration: 0.8)) {
            particles_visible = true
        }
    }
}

#Preview {
    AnimatedEmptyStateView()
}
