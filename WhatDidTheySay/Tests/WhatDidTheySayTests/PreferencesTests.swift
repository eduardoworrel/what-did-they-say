import Testing
import Foundation
@testable import WhatDidTheySayCore

// Preferences is @MainActor — all tests must run on the main actor.
@Suite("Preferences", .serialized)
@MainActor
struct PreferencesTests {

    // MARK: Mutation round-trips

    @Test("Setting targetLanguageId persists to UserDefaults")
    func targetLanguageIdPersists() {
        let prefs = Preferences.shared
        let original = prefs.targetLanguageId
        defer { prefs.targetLanguageId = original }

        prefs.targetLanguageId = "fr"
        #expect(prefs.targetLanguageId == "fr")
        #expect(UserDefaults.standard.string(forKey: "targetLanguageId") == "fr")
    }

    @Test("Setting sourceLanguageId persists to UserDefaults")
    func sourceLanguageIdPersists() {
        let prefs = Preferences.shared
        let original = prefs.sourceLanguageId
        defer { prefs.sourceLanguageId = original }

        prefs.sourceLanguageId = "de"
        #expect(prefs.sourceLanguageId == "de")
        #expect(UserDefaults.standard.string(forKey: "sourceLanguageId") == "de")
    }

    @Test("targetLanguageId is a non-empty string by default")
    func targetLanguageIdHasDefault() {
        // Default is "en" on a fresh install; just assert it is non-empty
        let prefs = Preferences.shared
        #expect(!prefs.targetLanguageId.isEmpty)
    }
}
