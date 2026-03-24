import Foundation

/// Manages downloaded ML model files in Application Support.
actor ModelCache {
    static let shared = ModelCache()

    private let baseURL: URL

    private init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        baseURL = appSupport.appendingPathComponent("Lingo/Models", isDirectory: true)
        try? FileManager.default.createDirectory(at: baseURL, withIntermediateDirectories: true)
    }

    // MARK: - Public API

    func isModelReady(modelId: String) -> Bool {
        let dir = modelDirectory(for: modelId)
        let readyMarker = dir.appendingPathComponent(".ready")
        return FileManager.default.fileExists(atPath: readyMarker.path)
    }

    func downloadModel(modelId: String, displayName: String) async {
        guard !isModelReady(modelId: modelId) else { return }

        let dir = modelDirectory(for: modelId)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        // Real download would use Hugging Face Hub API:
        //   GET https://huggingface.co/{modelId}/resolve/main/model.bin
        // For now, we post a notification so the UI can inform the user.
        await MainActor.run {
            NotificationCenter.default.post(
                name: .modelDownloadRequired,
                object: nil,
                userInfo: ["modelId": modelId, "displayName": displayName]
            )
        }
    }

    func modelDirectory(for modelId: String) -> URL {
        let safe = modelId.replacingOccurrences(of: "/", with: "_")
        return baseURL.appendingPathComponent(safe, isDirectory: true)
    }

    /// Mark a model as downloaded and ready (called after successful download).
    func markReady(modelId: String) throws {
        let readyMarker = modelDirectory(for: modelId).appendingPathComponent(".ready")
        try Data().write(to: readyMarker)
    }
}

extension Notification.Name {
    static let modelDownloadRequired = Notification.Name("LingoModelDownloadRequired")
}
