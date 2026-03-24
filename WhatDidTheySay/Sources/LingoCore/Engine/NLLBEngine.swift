import Foundation

// NLLB-200 (No Language Left Behind) — Meta's 200-language model.
// Runs locally via Core ML or swift-transformers.
// Model is downloaded on first use (~600 MB for the distilled variant).
//
// To enable: uncomment the swift-transformers dependency in Package.swift
// and the import below.

// #if canImport(Transformers)
// import Transformers
// #endif

public final class NLLBEngine: TranslationEngine, @unchecked Sendable {
    public let name = "NLLB-200"

    private let modelCache = ModelCache.shared

    // NLLB language code map (BCP-47 → NLLB flores code)
    private static let flores200: [String: String] = [
        "en": "eng_Latn",
        "es": "spa_Latn",
        "fr": "fra_Latn",
        "de": "deu_Latn",
        "pt": "por_Latn",
        "it": "ita_Latn",
        "nl": "nld_Latn",
        "ru": "rus_Cyrl",
        "zh": "zho_Hans",
        "ja": "jpn_Jpan",
        "ko": "kor_Hang",
        "ar": "arb_Arab",
        "hi": "hin_Deva",
        "tr": "tur_Latn",
        "pl": "pol_Latn",
        "uk": "ukr_Cyrl",
        "vi": "vie_Latn",
        "th": "tha_Thai",
        "id": "ind_Latn",
        "ms": "zsm_Latn",
    ]

    public func isAvailable() async -> Bool {
        // Available once model is downloaded
        return await modelCache.isModelReady(modelId: "facebook/nllb-200-distilled-600M")
    }

    public func translate(
        _ text: String,
        from source: Locale.Language,
        to target: Locale.Language
    ) async throws -> String {
        guard await isAvailable() else {
            throw TranslationError.engineNotAvailable
        }

        let srcCode = source.languageCode?.identifier ?? "en"
        let dstCode = target.languageCode?.identifier ?? "en"

        guard let _ = Self.flores200[srcCode], let _ = Self.flores200[dstCode] else {
            throw TranslationError.unsupportedLanguagePair(srcCode, dstCode)
        }

        // When swift-transformers is enabled, call the model here.
        // For now, this path is unreachable because isAvailable() returns false
        // until the model is downloaded.
        throw TranslationError.engineNotAvailable
    }

    /// Begin downloading the NLLB model in the background.
    func prefetchModel() {
        Task {
            await modelCache.downloadModel(
                modelId: "facebook/nllb-200-distilled-600M",
                displayName: "NLLB-200 (offline fallback, ~600 MB)"
            )
        }
    }
}
