//
//  ContentView.swift
//  MacLlamator
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var catalog: ModelCatalog
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
                    placeholder: String(localized: "Enter text…"),
                    onClear: { sourceText = "" },
                    onTranslate: manualTranslateAction
                )

                Divider()

                TranslationPaneView(
                    text: $translatedText,
                    isEditable: false,
                    placeholder: String(localized: "Translation"),
                    isLoading: isTranslating
                )
            }
        }
        .frame(minWidth: 760, minHeight: 480)
        // Cmd+Return translates whatever is in the pane right now, with the
        // automatic run on or off. A keyboard shortcut needs a button to
        // hang on, and this one has no business being visible: with the
        // automatic run off there is already a labelled button in the pane.
        .background {
            Button("", action: translateNow)
                .keyboardShortcut(.return, modifiers: .command)
                .hidden()
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                modelMenu
            }
            ToolbarItem(placement: .primaryAction) {
                Button {
                    openSettings()
                } label: {
                    Image(systemName: "gearshape")
                }
                .help("Settings")
            }
        }
        .task { await catalog.refresh(settings: settings) }
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
        .onChange(of: settings.autoTranslate) { _, isOn in
            // Switching the automatic run back on should catch up with the
            // text that is already there, not wait for the next keystroke.
            if isOn { scheduleTranslation(for: sourceText) }
        }
    }

    /// Shows the active model and lets it be switched without the detour
    /// through Settings. The label carries the current value the way
    /// MacLlamaStar's toolbar menus do, so the toolbar answers "which model
    /// is this running on?" without having to be opened.
    private var modelMenu: some View {
        Menu {
            if catalog.models.isEmpty {
                Text("No models found")
            } else {
                Picker("Model", selection: $settings.model) {
                    ForEach(catalog.models) { model in
                        Text(model.name).tag(model.name)
                    }
                }
                .pickerStyle(.inline)
                .labelsHidden()
            }

            Divider()

            Button {
                Task { await catalog.refresh(settings: settings) }
            } label: {
                Label("Refresh models", systemImage: "arrow.clockwise")
            }
            .disabled(catalog.isLoading)
        } label: {
            Label(modelMenuTitle, systemImage: "cpu")
                .labelStyle(.titleAndIcon)
        }
        .help("Active model")
    }

    private var modelMenuTitle: String {
        settings.model.isEmpty ? String(localized: "No model") : settings.model
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
            detectedLanguage = nil
            isTranslating = false
            return
        }

        // Detection is on-device and costs nothing, so it re-runs on every
        // change instead of settling on a first guess. A low-confidence
        // result leaves the previous detection standing rather than replacing
        // it with a guess, which keeps the badge steady mid-sentence while
        // still following a genuine switch of language.
        if sourceLanguage == .auto, let detected = LanguageDetector.detect(trimmed) {
            detectedLanguage = detected
        }

        // With the automatic run off nothing is sent until it is asked for.
        // Detection above still runs: it costs nothing and keeps the source
        // language badge honest while typing.
        guard settings.autoTranslate else { return }

        translationTask = Task {
            try? await Task.sleep(for: .milliseconds(settings.autoTranslateDelayMs))
            guard !Task.isCancelled else { return }
            await performTranslation(text: text)
        }
    }

    /// Only offered while nothing translates on its own; with the automatic
    /// run on, the button would sit there doing what has already happened.
    /// Written as an early return rather than a conditional expression: a
    /// conditional between `nil` and a method reference gives the type
    /// checker nothing to work from and it gives up without a diagnosis.
    private var manualTranslateAction: (() -> Void)? {
        guard !settings.autoTranslate else { return nil }
        return { translateNow() }
    }

    /// Translates at once, skipping the wait — the Cmd+Return path, and the
    /// button that appears when nothing translates on its own.
    private func translateNow() {
        translationTask?.cancel()
        errorMessage = nil

        let trimmed = sourceText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            translatedText = ""
            detectedLanguage = nil
            isTranslating = false
            return
        }

        if sourceLanguage == .auto, let detected = LanguageDetector.detect(trimmed) {
            detectedLanguage = detected
        }

        translationTask = Task { await performTranslation(text: sourceText) }
    }

    private func performTranslation(text: String) async {
        isTranslating = true
        defer { isTranslating = false }

        // Hand the model the language we detected rather than asking it to
        // work that out as well: the single-task prompt is the one models get
        // right. Falls back to .auto only when the text is still too short or
        // ambiguous to call, in which case the model does the detecting.
        let effectiveSource = effectiveSourceLanguage ?? .auto

        do {
            let result = try await service.translate(
                text: text,
                from: effectiveSource,
                to: targetLanguage,
                settings: settings
            )
            guard !Task.isCancelled else { return }
            translatedText = result.translatedText
            if let detected = result.detectedLanguage {
                detectedLanguage = detected
            }
            warnIfUntranslated(result.translatedText, from: effectiveSource)
        } catch {
            guard !Task.isCancelled else { return }
            errorMessage = error.localizedDescription
        }
    }

    /// Catches the failure where a model returns the source text instead of a
    /// translation. The result is still shown — it is simply flagged, rather
    /// than passing silently for a translation the user might send onwards.
    private func warnIfUntranslated(_ result: String, from source: Language) {
        guard !source.isAuto,
              source != targetLanguage,
              let resultLanguage = LanguageDetector.detect(result),
              resultLanguage == source
        else { return }

        errorMessage = String(
            localized: "The model returned the text untranslated — try a shorter passage or another model."
        )
    }
}

#Preview {
    ContentView()
        .environmentObject(AppSettings())
        .environmentObject(EditorFontSettings())
        .environmentObject(ModelCatalog())
}
