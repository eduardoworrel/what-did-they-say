import LingoCore
import SwiftUI

/// The main menu bar popover — text input → translation.
struct PopoverView: View {

    @State private var inputText = ""
    @State private var outputText = ""
    @State private var isTranslating = false
    @State private var errorMessage: String?
    @State private var sourceLanguage = Language.auto
    @State private var targetLanguage = Language.all.first(where: { $0.id == "en" }) ?? Language.all[0]

    @ObservedObject var screenTranslator: ScreenTranslator
    @ObservedObject var prefs: Preferences

    private let engine: any TranslationEngine

    init(engine: any TranslationEngine, screenTranslator: ScreenTranslator, prefs: Preferences) {
        self.engine = engine
        self.screenTranslator = screenTranslator
        self.prefs = prefs
    }

    var body: some View {
        VStack(spacing: 0) {
            headerBar
            Divider()
            inputSection
            Divider()
            outputSection
            Divider()
            footerBar
        }
        .frame(width: 360)
        .onAppear {
            // Restore last used languages from prefs
            if let src = Language.all.first(where: { $0.id == prefs.sourceLanguageId }) {
                sourceLanguage = src
            } else {
                sourceLanguage = Language.auto
            }
            if let dst = Language.all.first(where: { $0.id == prefs.targetLanguageId }) {
                targetLanguage = dst
            }
        }
    }

    // MARK: - Subviews

    private var headerBar: some View {
        HStack {
            Text("What Did They Say")
                .font(.system(size: 13, weight: .semibold))
            Spacer()
            LanguageButton(label: "From", selection: $sourceLanguage,
                           languages: [Language.auto] + Language.all)
            Image(systemName: "arrow.right")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)
            LanguageButton(label: "To", selection: $targetLanguage,
                           languages: Language.all)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .onChange(of: sourceLanguage) { _, new in prefs.sourceLanguageId = new.id }
        .onChange(of: targetLanguage) { _, new in prefs.targetLanguageId = new.id }
    }

    private var inputSection: some View {
        ZStack(alignment: .topLeading) {
            if inputText.isEmpty {
                Text("Type or paste text to translate…")
                    .foregroundStyle(.tertiary)
                    .font(.system(size: 13))
                    .padding(.horizontal, 12)
                    .padding(.top, 10)
            }
            TextEditor(text: $inputText)
                .font(.system(size: 13))
                .frame(height: 90)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .scrollContentBackground(.hidden)
        }
    }

    private var outputSection: some View {
        ZStack(alignment: .topLeading) {
            if isTranslating {
                ProgressView()
                    .controlSize(.small)
                    .padding(12)
            } else if let error = errorMessage {
                Text(error)
                    .foregroundStyle(.red)
                    .font(.system(size: 12))
                    .padding(12)
            } else if outputText.isEmpty {
                Text("Translation will appear here")
                    .foregroundStyle(.tertiary)
                    .font(.system(size: 13))
                    .padding(12)
            } else {
                ScrollView {
                    Text(outputText)
                        .font(.system(size: 13))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                }
                .frame(height: 90)
            }
        }
        .frame(minHeight: 90)
        .background(.background.opacity(0.5))
    }

    private var footerBar: some View {
        HStack(spacing: 8) {
            // Screen translate toggle
            Button {
                Task {
                    await screenTranslator.toggle(targetLanguage: targetLanguage.locale)
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: screenTranslator.isActive ? "stop.fill" : "camera.viewfinder")
                        .font(.system(size: 12))
                    Text(screenTranslator.isActive ? "Stop" : "Screen")
                        .font(.system(size: 12, weight: .medium))
                }
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .tint(screenTranslator.isActive ? .red : .accentColor)

            Spacer()

            // Copy button
            if !outputText.isEmpty {
                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(outputText, forType: .string)
                } label: {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 12))
                }
                .buttonStyle(.borderless)
                .controlSize(.small)
                .help("Copy translation")
            }

            // Translate button
            Button("Translate") {
                translateInput()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
            .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isTranslating)
            .keyboardShortcut(.return, modifiers: .command)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    // MARK: - Actions

    private func translateInput() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        isTranslating = true
        errorMessage = nil
        outputText = ""

        Task {
            do {
                let src = sourceLanguage.id.isEmpty
                    ? Locale.Language(identifier: "")
                    : Locale.Language(identifier: sourceLanguage.id)
                let result = try await engine.translate(text, from: src, to: targetLanguage.locale)
                outputText = result
            } catch {
                errorMessage = error.localizedDescription
            }
            isTranslating = false
        }
    }
}
