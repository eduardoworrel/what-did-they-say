import Testing
import Foundation
@testable import WhatDidTheySayCore

// MARK: - Mock Engines

/// Always succeeds with a predictable result.
final class MockSuccessEngine: TranslationEngine, @unchecked Sendable {
    let name = "MockSuccess"
    var callCount = 0

    func isAvailable() async -> Bool { true }

    func translate(_ text: String, from source: Locale.Language, to target: Locale.Language) async throws -> String {
        callCount += 1
        return "[\(target.languageCode?.identifier ?? "??")] \(text)"
    }
}

/// Always reports unavailable.
final class MockUnavailableEngine: TranslationEngine, @unchecked Sendable {
    let name = "MockUnavailable"

    func isAvailable() async -> Bool { false }

    func translate(_ text: String, from source: Locale.Language, to target: Locale.Language) async throws -> String {
        throw TranslationError.engineNotAvailable
    }
}

/// Always throws a specific error.
final class MockFailingEngine: TranslationEngine, @unchecked Sendable {
    let name = "MockFailing"
    let error: TranslationError

    init(error: TranslationError = .translationFailed("deliberate failure")) {
        self.error = error
    }

    func isAvailable() async -> Bool { true }

    func translate(_ text: String, from source: Locale.Language, to target: Locale.Language) async throws -> String {
        throw error
    }
}

// MARK: - TranslationError Tests

@Suite("TranslationError")
struct TranslationErrorTests {

    @Test("All cases have non-empty errorDescription")
    func allCasesHaveDescription() {
        let cases: [TranslationError] = [
            .unsupportedLanguagePair("en", "xx"),
            .engineNotAvailable,
            .translationFailed("oops"),
            .timeout,
            .permissionDenied,
        ]
        for error in cases {
            #expect(error.errorDescription != nil)
            #expect(!(error.errorDescription!.isEmpty))
        }
    }

    @Test("unsupportedLanguagePair embeds language codes")
    func unsupportedPairEmbedsLanguages() {
        let error = TranslationError.unsupportedLanguagePair("fr", "de")
        #expect(error.errorDescription!.contains("fr"))
        #expect(error.errorDescription!.contains("de"))
    }

    @Test("translationFailed embeds reason string")
    func failedEmbedsReason() {
        let reason = "network unavailable"
        let error = TranslationError.translationFailed(reason)
        #expect(error.errorDescription!.contains(reason))
    }
}

// MARK: - CompositeTranslationEngine Tests

@Suite("CompositeTranslationEngine")
struct CompositeTranslationEngineTests {

    private let en = Locale.Language(identifier: "en")
    private let es = Locale.Language(identifier: "es")

    // MARK: isAvailable

    @Test("isAvailable is true when at least one engine is available")
    func isAvailableTrue() async {
        let engine = CompositeTranslationEngine(engines: [MockUnavailableEngine(), MockSuccessEngine()])
        #expect(await engine.isAvailable() == true)
    }

    @Test("isAvailable is false when all engines are unavailable")
    func isAvailableFalseAllUnavailable() async {
        let engine = CompositeTranslationEngine(engines: [MockUnavailableEngine(), MockUnavailableEngine()])
        #expect(await engine.isAvailable() == false)
    }

    @Test("isAvailable is false for empty engine list")
    func isAvailableFalseEmpty() async {
        let engine = CompositeTranslationEngine(engines: [])
        #expect(await engine.isAvailable() == false)
    }

    // MARK: translate — success

    @Test("translate returns result from first successful engine")
    func translateSucceeds() async throws {
        let success = MockSuccessEngine()
        let engine = CompositeTranslationEngine(engines: [success])
        let result = try await engine.translate("hello", from: en, to: es)
        #expect(result == "[es] hello")
        #expect(success.callCount == 1)
    }

    @Test("translate skips failing engine and uses second")
    func translateFallsBackToSecond() async throws {
        let failing = MockFailingEngine()
        let success = MockSuccessEngine()
        let engine = CompositeTranslationEngine(engines: [failing, success])
        let result = try await engine.translate("world", from: en, to: es)
        #expect(result == "[es] world")
        #expect(success.callCount == 1)
    }

    @Test("translate skips unavailable engine and uses available")
    func translateSkipsUnavailable() async throws {
        let engine = CompositeTranslationEngine(engines: [MockUnavailableEngine(), MockSuccessEngine()])
        let result = try await engine.translate("test", from: en, to: es)
        #expect(result == "[es] test")
    }

    // MARK: translate — failure

    @Test("translate throws last error when all engines fail")
    func translateThrowsLastError() async {
        let engine = CompositeTranslationEngine(engines: [
            MockFailingEngine(error: .translationFailed("first")),
            MockFailingEngine(error: .translationFailed("second")),
        ])
        await #expect(throws: TranslationError.self) {
            _ = try await engine.translate("x", from: en, to: es)
        }
    }

    @Test("translate throws engineNotAvailable for empty engine list")
    func translateThrowsForEmpty() async {
        let engine = CompositeTranslationEngine(engines: [])
        await #expect(throws: TranslationError.self) {
            _ = try await engine.translate("x", from: en, to: es)
        }
    }

    // MARK: name

    @Test("composite engine name is 'What Did They Say'")
    func compositeName() {
        let engine = CompositeTranslationEngine(engines: [])
        #expect(engine.name == "What Did They Say")
    }
}
