# Offline AI Chat

A native iOS app for running AI language models completely offline on your device. No internet required, no data leaves your phone.

## Features

- **100% Offline**: All AI inference runs locally on your device
- **Multiple Models**: Choose from various models (0.6B to 7B parameters)
- **Chat Sessions**: Save and manage multiple conversations
- **Memory System**: Persistent memory across conversations
- **Model Management**: Download, switch, and delete models easily
- **Privacy First**: Your conversations never leave your device

## Supported Models

| Model | Size | RAM | Best For |
|-------|------|-----|----------|
| Qwen3 0.6B | 639MB | ~750MB | Ultra-fast responses |
| TinyLlama 1.1B | 638MB | ~800MB | Quick chat |
| Qwen2.5 1.5B | 986MB | ~1.1GB | Balanced quality/speed |
| Gemma 2 2B | 1.5GB | ~1.7GB | Google's efficient model |
| Phi-3 Mini | 2.2GB | ~2.5GB | Microsoft's powerhouse |
| Llama 3.2 3B | 2GB | ~2.3GB | Great reasoning |
| Qwen2.5 3B | 1.9GB | ~2.2GB | Multilingual support |
| StarCoder2 3B | 1.8GB | ~2.1GB | Code generation |
| DeepSeek Coder 1.3B | 800MB | ~950MB | Fast code assistant |
| Mistral 7B | 4.1GB | ~4.8GB | Highest quality |

## Requirements

- **iOS 16.0+** or **macOS 13.0+**
- **Xcode 15.0+**
- **Apple Silicon** (M1/M2/M3) for macOS, or **A14 Bionic+** for iOS
- Sufficient storage for model downloads (639MB - 4.1GB per model)

## Setup Instructions

### 1. Clone the Repository

```bash
git clone https://github.com/chaganti-sairam/offline-ios-local-app.git
cd offline-ios-local-app
```

### 2. Open in Xcode

```bash
open OfflineAIChat.xcodeproj
```

### 3. Configure Signing

1. Select the `OfflineAIChat` target
2. Go to **Signing & Capabilities**
3. Select your **Team** (Personal Team works for development)
4. Xcode will automatically manage signing

### 4. Build and Run

1. Select your target device (iPhone or Mac)
2. Press `Cmd + R` or click the **Run** button
3. Wait for the build to complete

### 5. Download a Model

1. Open the app
2. Tap the **gear icon** (settings)
3. Go to **Model Settings**
4. Choose a model and tap **Download**
5. Wait for the download to complete (can take several minutes)

### 6. Start Chatting

Once a model is downloaded, you can start chatting immediately. The app will use the selected model for all conversations.

## Project Structure

```
OfflineAIChat/
├── OfflineAIChat/
│   ├── Models/              # Data models
│   │   ├── chat_message_model.swift
│   │   ├── chat_session_model.swift
│   │   ├── memory_model.swift
│   │   └── model_configuration.swift
│   ├── Views/               # SwiftUI views
│   │   ├── chat_conversation_view.swift
│   │   ├── model_settings_view.swift
│   │   ├── memory_settings_view.swift
│   │   └── ...
│   ├── ViewModels/          # View logic
│   │   └── chat_conversation_view_model.swift
│   ├── Services/            # Business logic
│   │   ├── nexa_inference_service.swift
│   │   ├── model_download_service.swift
│   │   ├── chat_storage_service.swift
│   │   └── memory_storage_service.swift
│   ├── NexaSdk.xcframework/ # AI inference SDK
│   └── OfflineAIChatApp.swift
└── OfflineAIChat.xcodeproj/
```

## How It Works

The app uses the **Nexa SDK** for on-device AI inference:

1. **Model Download**: GGUF-formatted models are downloaded from Hugging Face
2. **Model Loading**: The Nexa SDK loads the model into memory
3. **Inference**: User messages are processed locally using the loaded model
4. **Streaming**: Responses are streamed token-by-token for a natural feel

## Tips for Best Experience

- **Start with smaller models** (Qwen3 0.6B or TinyLlama) for faster responses
- **Use larger models** (Llama 3.2 3B or Mistral 7B) for better quality
- **Close other apps** to free up RAM for larger models
- **Keep the app in foreground** during model downloads
- **Enable Memory** to maintain context across conversations

## Troubleshooting

### Model won't load
- Ensure you have enough free RAM
- Try a smaller model first
- Restart the app and try again

### Download stuck
- Check your internet connection
- The app supports download resumption - pause and resume
- Try deleting the model and re-downloading

### Slow responses
- Larger models are slower but higher quality
- Try Qwen3 0.6B or TinyLlama for fastest responses
- Ensure no other apps are using significant memory

## Privacy

- All AI inference happens **on-device**
- No data is sent to any server
- Conversations are stored locally using SwiftData
- Model files are downloaded directly from Hugging Face

## License

MIT License - See [LICENSE](LICENSE) for details

## Credits

- **Nexa AI** for the on-device inference SDK
- **Hugging Face** for hosting the model files
- All the amazing open-source model creators

## Roadmap

We're building towards a fully-featured offline AI assistant. Here's what's planned:

### Local RAG (Retrieval-Augmented Generation)

- [ ] **FAISS Integration** - Facebook AI Similarity Search for fast vector similarity
- [ ] **HNSW Index** - Hierarchical Navigable Small World graphs for approximate nearest neighbor search
- [ ] **Local Embeddings** - On-device text embedding models (all-MiniLM, bge-small, etc.)
- [ ] **Document Ingestion** - Import PDFs, text files, and notes for context
- [ ] **Smart Chunking** - Intelligent document splitting for better retrieval
- [ ] **Binary Index Storage** - Efficient `.bin` file format for vector indices

### Model Enhancements

- [ ] **Custom Model Import** - Add your own GGUF models
- [ ] **Model Quantization Options** - Choose between Q4, Q5, Q8 variants
- [ ] **Embedding Model Selection** - Multiple embedding models for RAG
- [ ] **Vision Models** - Local image understanding (LLaVA, etc.)
- [ ] **Voice Input** - Whisper-based speech-to-text (Nexa SDK supported)
- [ ] **Voice Output** - Text-to-speech for responses (Nexa SDK supported)
- [ ] **Voice Conversations** - Full voice-to-voice chat mode

### Knowledge Base

- [ ] **Personal Knowledge Graph** - Connect related memories and documents
- [ ] **Folder-Based Collections** - Organize documents by topic
- [ ] **Automatic Tagging** - AI-powered document categorization
- [ ] **Search & Filter** - Full-text search across all your data
- [ ] **Export/Import** - Backup and restore your knowledge base

### UI/UX Improvements

- [ ] **iPad Support** - Optimized layout for larger screens
- [ ] **macOS Catalyst** - Native Mac experience
- [ ] **Widgets** - Quick access from home screen
- [ ] **Shortcuts Integration** - Siri and automation support
- [ ] **Dark/Light Themes** - System-aware theming
- [ ] **Chat Export** - Share conversations as PDF/Markdown

### Performance

- [ ] **Metal Acceleration** - GPU-accelerated inference
- [ ] **Speculative Decoding** - Faster response generation
- [ ] **Context Caching** - Reduce memory reloads
- [ ] **Background Processing** - Continue tasks when app is backgrounded
- [ ] **Batch Processing** - Process multiple queries efficiently

### Advanced Features

- [ ] **Agents & Tools** - Function calling for local actions
- [ ] **Web Browsing** - Optional web search with privacy
- [ ] **Code Execution** - Safe local code sandbox
- [ ] **Multi-Turn Planning** - Complex task decomposition
- [ ] **Personality Customization** - System prompt templates

## Contributing

Contributions are welcome! We'd love your help making offline AI accessible to everyone.

### How to Contribute

1. **Fork the repository**
2. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```
3. **Make your changes**
4. **Test thoroughly** on both iOS and macOS if possible
5. **Submit a Pull Request**

### Contribution Ideas

| Area | Description | Difficulty |
|------|-------------|------------|
| FAISS Integration | Implement local vector search | Hard |
| HNSW Index | Add HNSW-based similarity search | Hard |
| Voice Mode | Whisper STT + TTS using Nexa SDK | Medium |
| Document Parser | PDF/DOCX text extraction | Medium |
| Embedding Models | Integrate local embedding models | Medium |
| UI Improvements | Better chat bubbles, animations | Easy |
| Model Support | Add new model configurations | Easy |
| Bug Fixes | Fix issues from the tracker | Varies |
| Documentation | Improve README, add guides | Easy |
| Tests | Add unit and UI tests | Medium |
| Localization | Translate to other languages | Easy |

### Development Guidelines

- Follow existing code style and naming conventions
- Add comments for complex logic
- Test on real devices when possible
- Keep PRs focused and atomic
- Update documentation for new features

### Reporting Issues

Found a bug? Have a feature request? Please [open an issue](https://github.com/chaganti-sairam/offline-ios-local-app/issues) with:

- Clear description of the problem/request
- Steps to reproduce (for bugs)
- Device and iOS version
- Screenshots if applicable

### Code of Conduct

Be respectful, inclusive, and constructive. We're all here to learn and build together.
