//
//  ContentView.swift
//  MacLlamator
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var settings: OllamaSettings
    @Environment(\.openSettings) private var openSettings

    private let service = OllamaService()

    @State private var sourceLanguage: Language = .auto
    @State private var targetLanguage: Language = Language.all.first { $0.code == "en" } ?? Language.all[0]
    @State private var detectedLanguage: Language?

    @State private var sourceText: String = ""
    @State private var translatedText: String = ""

    @State private var isTranslating = false
    @State private var errorMessage: String?
    @State private var translationTask: Task<Void, Never>?

    var body: some View {
        VStack(spacing: 0) {
            languageBar

            if let errorMessage {
                Text(errorMessage)
                    .font(.callout)
                    .foregroundStyle(.red)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Divider()

            HStack(spacing: 0) {
                TranslationPaneView(
                    text: $sourceText,
                    isEditable: true,
                    placeholder: "Enter text…",
                    onClear: { sourceText = "" }
                )

                Divider()

                TranslationPaneView(
                    text: $translatedText,
                    isEditable: false,
                    placeholder: "Translation",
                    isLoading: isTranslating
                )
            }
        }
        .frame(minWidth: 760, minHeight: 480)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    openSettings()
                } label: {
                    Image(systemName: "gearshape")
                }
                .help("Settings")
            }
        }
        .onChange(of: sourceText) { _, newValue in
            scheduleTranslation(for: newValue)
        }
        .onChange(of: detectedLanguage) { _, newValue in
            applyPreferredTargetIfNeeded(for: newValue)
        }
        .onChange(of: sourceLanguage) { _, _ in
            detectedLanguage = nil
            scheduleTranslation(for: sourceText)
        }
        .onChange(of: targetLanguage) { _, _ in
            scheduleTranslation(for: sourceText)
        }
    }

    private var languageBar: some View {
        HStack(spacing: 0) {
            languageMenu(
                selection: sourceLanguage,
                displayName: sourceDisplayName,
                options: Language.sourceOptions
            ) { sourceLanguage = $0 }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                swapLanguages()
            } label: {
                Image(systemName: "arrow.left.arrow.right")
            }
            .buttonStyle(.plain)
            .disabled(effectiveSourceLanguage == nil)
            .help("Swap languages")
            .padding(.horizontal, 16)

            languageMenu(
                selection: targetLanguage,
                displayName: targetLanguage.displayName,
                options: Language.all
            ) { targetLanguage = $0 }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    /// The concrete language currently backing "automatisch erkennen" (once
    /// detected), or the explicitly selected source language otherwise.
    private var effectiveSourceLanguage: Language? {
        sourceLanguage == .auto ? detectedLanguage : sourceLanguage
    }

    private var sourceDisplayName: String {
        guard sourceLanguage == .auto else { return sourceLanguage.displayName }
        guard let detectedLanguage else { return sourceLanguage.displayName }
        return String(localized: "\(detectedLanguage.displayName) (detected)")
    }

    private func languageMenu(
        selection: Language,
        displayName: String,
        options: [Language],
        onSelect: @escaping (Language) -> Void
    ) -> some View {
        Menu {
            ForEach(options) { language in
                Button {
                    onSelect(language)
                } label: {
                    if language == selection {
                        Label(language.displayName, systemImage: "checkmark")
                    } else {
                        Text(language.displayName)
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(displayName)
                    .fontWeight(.medium)
                Image(systemName: "chevron.down")
                    .font(.caption2)
            }
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
    }

    private func swapLanguages() {
        guard let newTarget = effectiveSourceLanguage else { return }
        let newSource = targetLanguage
        sourceLanguage = newSource
        targetLanguage = newTarget
        detectedLanguage = nil
        sourceText = translatedText
    }

    /// When auto-detection recognizes one of the two preferred languages
    /// (set in Settings), automatically switches the target to the other
    /// preferred language — e.g. detecting German selects English, and
    /// detecting English selects German, without the user re-picking it.
    private func applyPreferredTargetIfNeeded(for detected: Language?) {
        guard let detected else { return }
        guard let languageA = Language.all.first(where: { $0.code == settings.preferredLanguageA }),
              let languageB = Language.all.first(where: { $0.code == settings.preferredLanguageB }) else { return }

        if detected == languageA, targetLanguage != languageB {
            targetLanguage = languageB
        } else if detected == languageB, targetLanguage != languageA {
            targetLanguage = languageA
        }
    }

    private func scheduleTranslation(for text: String) {
        translationTask?.cancel()
        errorMessage = nil

        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            translatedText = ""
            isTranslating = false
            return
        }

        translationTask = Task {
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled else { return }
            await performTranslation(text: text)
        }
    }

    private func performTranslation(text: String) async {
        isTranslating = true
        defer { isTranslating = false }

        do {
            let result = try await service.translate(
                text: text,
                from: sourceLanguage,
                to: targetLanguage,
                settings: settings
            )
            guard !Task.isCancelled else { return }
            translatedText = result.translatedText
            if let detected = result.detectedLanguage {
                detectedLanguage = detected
            }
        } catch {
            guard !Task.isCancelled else { return }
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(OllamaSettings())
        .environmentObject(EditorFontSettings())
}
