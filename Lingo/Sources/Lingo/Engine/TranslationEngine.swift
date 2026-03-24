import Foundation

// MARK: - Errors

enum TranslationError: Error, LocalizedError {
    case unsupportedLanguagePair(String, String)
    case engineNotAvailable
    case translationFailed(String)
    case timeout
    case permissionDenied

    var errorDescription: String? {
        switch self {
        case .unsupportedLanguagePair(let src, let dst):
            return "Translation from \(src) to \(dst) is not supported"
        case .engineNotAvailable:
            return "Translation engine is not available on this system"
        case .translationFailed(let reason):
            return "Translation failed: \(reason)"
        case .timeout:
            return "Translation timed out — please try again"
        case .permissionDenied:
            return "Translation permission was denied"
        }
    }
}

// MARK: - Protocol

/// All translation backends conform to this protocol.
protocol TranslationEngine: AnyObject, Sendable {
    var name: String { get }

    /// Returns true if this engine can be used on the current system.
    func isAvailable() async -> Bool

    /// Translates `text` from `source` language to `target` language.
    func translate(
        _ text: String,
        from source: Locale.Language,
        to target: Locale.Language
    ) async throws -> String
}

// MARK: - Composite engine (tries Apple first, falls back to NLLB)

final class CompositeTranslationEngine: TranslationEngine, @unchecked Sendable {
    let name = "Lingo"

    private let engines: [any TranslationEngine]

    init(engines: [any TranslationEngine]) {
        self.engines = engines
    }

    func isAvailable() async -> Bool {
        for engine in engines {
            if await engine.isAvailable() { return true }
        }
        return false
    }

    func translate(
        _ text: String,
        from source: Locale.Language,
        to target: Locale.Language
    ) async throws -> String {
        var lastError: Error = TranslationError.engineNotAvailable

        for engine in engines {
            guard await engine.isAvailable() else { continue }
            do {
                return try await engine.translate(text, from: source, to: target)
            } catch {
                lastError = error
                // Try next engine
            }
        }

        throw lastError
    }
}

// MARK: - Shared instance

@MainActor
final class TranslationEngineProvider {
    static let shared = TranslationEngineProvider()

    let engine: any TranslationEngine

    private init() {
        var engines: [any TranslationEngine] = []

        if #available(macOS 26, *) {
            engines.append(AppleTranslationEngine())
        }
        engines.append(NLLBEngine())

        self.engine = CompositeTranslationEngine(engines: engines)
    }
}
