//
//  LanguageSettingsPane.swift
//  MacLlamator
//

import SwiftUI

/// Which languages the app offers at all. A page to itself because the list
/// of ticks is tall enough to bury anything sharing a column with it; which
/// two of them are preferred belongs with the translation settings.
struct LanguageSettingsPane: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var catalog: ModelCatalog

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SettingsSection("Available languages") {
                Text("Only the ticked languages appear in the pickers. Which ones are worth offering depends on the model and on what you actually translate — both of which you know better than the app does.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                languageList

                HStack {
                    Button("All") {
                        settings.enabledLanguageCodes = Language.allCodes
                    }
                    .disabled(settings.enabledLanguageCodes == Language.allCodes)

                    Button("Preferred pair only") {
                        settings.enabledLanguageCodes = [
                            settings.preferredLanguageA, settings.preferredLanguageB,
                        ]
                    }
                    .disabled(settings.preferredLanguageA == settings.preferredLanguageB)

                    Spacer()
                }

                // On its own row: model names run long — "llama3.1:8b" is
                // already enough to truncate the label beside two others, and
                // nothing stops one being twice that.
                if let claimed = claimedCodes, !claimed.isEmpty {
                    Button(String(localized: "Only what \(settings.model) lists")) {
                        settings.enabledLanguageCodes = claimed
                    }
                    .disabled(settings.enabledLanguageCodes == claimed)
                    .lineLimit(1)
                }
            }

        }
        .settingsPaneLayout()
        .task(id: settings.model) {
            await catalog.refreshDeclaredLanguages(for: settings.model, settings: settings)
        }
    }

    /// What the active model says it handles, for the shortcut button and the
    /// markers in the list. Nil when neither the model file nor our table has
    /// anything to say, in which case nothing is suggested at all.
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
        .frame(height: 240)
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
}

#Preview {
    LanguageSettingsPane()
        .environmentObject(AppSettings())
        .environmentObject(ModelCatalog())
}
