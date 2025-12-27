import SwiftUI

/// This view is no longer used - keeping for reference only
/// The main chat view now handles model status display
struct ModelStatusIndicatorView: View {
    @ObservedObject var inference_service: NexaInferenceService
    @ObservedObject var download_service: ModelDownloadService
    let on_model_ready: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            switch inference_service.loading_state {
            case .uninitialized:
                no_model_view
            case .loading:
                loading_view
            case .ready:
                ready_view
            case .error(let message):
                error_view(message: message)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .onChange(of: inference_service.loading_state) { _, new_state in
            if case .ready = new_state {
                on_model_ready()
            }
        }
    }

    private var no_model_view: some View {
        VStack(spacing: 16) {
            Image(systemName: "square.and.arrow.down")
                .font(.system(size: 48))
                .foregroundColor(.blue)

            Text("No Model Loaded")
                .font(.headline)

            Text("Select a model in settings to download and use")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }

    private var loading_view: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)

            Text("Loading Model...")
                .font(.headline)

            if let model = download_service.active_model {
                Text(model.display_name)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var ready_view: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundColor(.green)

            Text("Model Ready")
                .font(.headline)

            if let model = inference_service.loaded_model {
                Text(model.display_name)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }

    private func error_view(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.red)

            Text("Failed to Load Model")
                .font(.headline)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button("Retry") {
                Task {
                    if let model = download_service.active_model {
                        try? await inference_service.load_model(model)
                    }
                }
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

#Preview {
    ModelStatusIndicatorView(
        inference_service: NexaInferenceService(),
        download_service: ModelDownloadService(),
        on_model_ready: {}
    )
}
