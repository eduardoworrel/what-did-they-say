import Foundation

// Apple's Translation framework is available on macOS 14+.
// The programmatic API (TranslationSession without SwiftUI) landed in macOS 26.
// For macOS 14–25, we fall through to the NLLBEngine fallback.
// This class wraps the direct session API available on macOS 26+.

#if canImport(Translation)
import Translation

@available(macOS 26, *)
public final class AppleTranslationEngine: TranslationEngine, @unchecked Sendable {
    public let name = "Apple Translation"

    // Cache sessions keyed by "src_dst" to avoid recreating them
    private var sessions: [String: TranslationSession] = [:]
    private let lock = NSLock()

    public func isAvailable() async -> Bool { true }

    public func translate(
        _ text: String,
        from source: Locale.Language,
        to target: Locale.Language
    ) async throws -> String {
        let key = "\(source.languageCode?.identifier ?? "auto")_\(target.languageCode?.identifier ?? "en")"

        let session = lock.withLock {
            if let existing = sessions[key] { return existing }
            let newSession = TranslationSession(installedSource: source, target: target)
            sessions[key] = newSession
            return newSession
        }

        do {
            let response = try await session.translate(text)
            return response.targetText
        } catch let error as TranslationError {
            throw error
        } catch {
            throw TranslationError.translationFailed(error.localizedDescription)
        }
    }
}

#else

// Fallback stub for systems where Translation framework is not importable (< macOS 14)
public final class AppleTranslationEngine: TranslationEngine, @unchecked Sendable {
    public let name = "Apple Translation"
    public func isAvailable() async -> Bool { false }
    public func translate(_ text: String, from source: Locale.Language, to target: Locale.Language) async throws -> String {
        throw TranslationError.engineNotAvailable
    }
}

#endif
