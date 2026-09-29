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

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SettingsSection("Preferred languages") {
                Text("When automatic detection recognizes one of these two languages, the other is selected as the target language.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack {
                    Text("Language 1")
                    Spacer()
                    Picker("Language 1", selection: $settings.preferredLanguageA) {
                        ForEach(Language.all) { language in
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
                        ForEach(Language.all) { language in
                            Text(language.displayName).tag(language.code)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 160)
                }
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
    }
}

#Preview {
    TranslationSettingsPane()
        .environmentObject(AppSettings())
}
