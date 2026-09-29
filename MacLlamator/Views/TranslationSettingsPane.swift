//
//  TranslationSettingsPane.swift
//  MacLlamator
//

import SwiftUI

/// Everything about how translation behaves — the language pair it prefers
/// and the extra instructions the model is given — as opposed to where it
/// runs, which is the Ollama pane's business.
struct TranslationSettingsPane: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var catalog: ModelCatalog

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SettingsSection("Languages") {
                Text("Only the ticked languages appear in the pickers. Which ones are worth offering depends on the model and on what you actually translate — both of which you know better than the app does.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                languageList

                HStack {
                    Button("All") {
                        settings.enabledLanguageCodes = Language.allCodes
                    }
                    .disabled(settings.enabledLanguageCodes.count == Language.all.count)

                    Button("Preferred pair only") {
                        settings.enabledLanguageCodes = [
                            settings.preferredLanguageA, settings.preferredLanguageB,
                        ]
                    }
                    .disabled(settings.preferredLanguageA == settings.preferredLanguageB)

                    Spacer()

                    if let claimed = claimedCodes, !claimed.isEmpty {
                        Button(String(localized: "Only what \(settings.model) lists")) {
                            settings.enabledLanguageCodes = claimed
                        }
                        .disabled(settings.enabledLanguageCodes == claimed)
                    }
                }
            }

            SettingsSection("Preferred languages") {
                Text("When automatic detection recognizes one of these two languages, the other is selected as the target language.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack {
                    Text("Language 1")
                    Spacer()
                    Picker("Language 1", selection: $settings.preferredLanguageA) {
                        ForEach(settings.enabledLanguages) { language in
                            Text(language.displayName).tag(language.code)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 160)
                }

                Divider()

                HStack {
                    Text("Language 2")
                    Spacer()
                    Picker("Language 2", selection: $settings.preferredLanguageB) {
                        ForEach(settings.enabledLanguages) { language in
                            Text(language.displayName).tag(language.code)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 160)
                }
            }

            SettingsSection("Automatic translation") {
                Toggle("Translate while typing", isOn: $settings.autoTranslate)

                Divider()

                HStack {
                    Text("Wait before translating")
                    Spacer()
                    Picker("Wait before translating", selection: $settings.autoTranslateDelayMs) {
                        ForEach(AppSettings.autoTranslateDelayOptions, id: \.self) { milliseconds in
                            Text(Self.delayLabel(milliseconds)).tag(milliseconds)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 160)
                }
                .disabled(!settings.autoTranslate)

                Text("How long the text has to stay unchanged before a translation is sent. With automatic translation switched off, nothing is sent until Cmd+Return asks for it.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            SettingsSection("Prompt") {
                Text("Additional instructions for the model (optional), e.g. about tone or terminology.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                TextEditor(text: $settings.customInstructions)
                    .font(.system(size: 12))
                    .frame(height: 80)
                    .padding(4)
                    .overlay {
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                    }

                HStack {
                    Spacer()
                    Button("Reset") {
                        settings.customInstructions = ""
                    }
                    .disabled(settings.customInstructions.isEmpty)
                }
            }
        }
        .settingsPaneLayout()
        .task(id: settings.model) {
            await catalog.refreshDeclaredLanguages(for: settings.model, settings: settings)
        }
    }

    /// What the active model says it handles, for the shortcut button and
    /// the hints in the list. Nil when neither the model file nor our table
    /// has anything to say, in which case nothing is suggested at all.
    private var claimedCodes: Set<String>? {
        guard let claimed = catalog.claimedLanguageCodes(for: settings.model) else { return nil }
        // Only ever narrow to languages this app actually offers.
        return claimed.intersection(Language.allCodes)
    }

    private var languageList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 4) {
                // Resolved once rather than per row: every row asks the same
                // question about the same model.
                let claimed = claimedCodes
                ForEach(Language.all) { language in
                    languageRow(language, claimed: claimed)
                }
            }
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: 180)
        .overlay {
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
        }
    }

    private func languageRow(_ language: Language, claimed: Set<String>?) -> some View {
        let isOn = settings.enabledLanguageCodes.contains(language.code)
        // The last two ticks stay put: with fewer there is nothing to swap
        // between, and an empty picker is not a state worth reaching.
        let isPinned = isOn
            && settings.enabledLanguageCodes.count <= AppSettings.minimumEnabledLanguages
        let isUnlisted = claimed.map { !$0.contains(language.code) } ?? false

        return Toggle(isOn: Binding(
            get: { isOn },
            set: { wanted in
                if wanted {
                    settings.enabledLanguageCodes.insert(language.code)
                } else {
                    settings.enabledLanguageCodes.remove(language.code)
                }
            }
        )) {
            HStack(spacing: 6) {
                Text(language.displayName)
                if isUnlisted {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundStyle(.secondary)
                        .help("Not among the languages this model lists")
                }
            }
        }
        .disabled(isPinned)
    }

    private static func delayLabel(_ milliseconds: Int) -> String {
        guard milliseconds >= 1000 else { return "\(milliseconds) ms" }
        let seconds = Double(milliseconds) / 1000
        return seconds == seconds.rounded()
            ? "\(Int(seconds)) s"
            : String(format: "%.1f s", seconds)
    }
}

#Preview {
    TranslationSettingsPane()
        .environmentObject(AppSettings())
        .environmentObject(ModelCatalog())
}
