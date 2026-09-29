//
//  TranslationSettingsPane.swift
//  MacLlamator
//

import SwiftUI

/// How translation behaves: which pair it flips between, how eagerly it
/// runs, and what the model is told beyond the text. Which languages exist
/// at all is the language pane's business, and where it runs is Ollama's.
struct TranslationSettingsPane: View {
    @EnvironmentObject private var settings: AppSettings

    /// Tag of the "off" row. Negative so it can never collide with a delay.
    private static let offTag = -1

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SettingsSection("Preferred languages") {
                Text("When automatic detection recognizes one of these two languages, the other is selected as the target language.")
                    .font(.settingsNote)
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

            SettingsSection("Automatic translation while typing") {
                // No row label: the section heading names the setting, and
                // each value reads as a full answer to it — including "off",
                // which is why switching it on and off is not a separate
                // checkbox. One decision, one control.
                Picker("Automatic translation while typing", selection: autoTranslateSelection) {
                    ForEach(AppSettings.autoTranslateDelayOptions, id: \.self) { milliseconds in
                        Text(Self.delayLabel(milliseconds)).tag(milliseconds)
                    }
                    Divider()
                    Text("Off — only on Cmd+Return").tag(Self.offTag)
                }
                .labelsHidden()
                .frame(width: 220)

                Text("How long the text has to stay unchanged before it is translated automatically. Switched off, nothing is sent until Cmd+Return asks for it.")
                    .font(.settingsNote)
                    .foregroundStyle(.secondary)
            }

            SettingsSection("Prompt") {
                Text("Additional instructions for the model (optional), e.g. about tone or terminology.")
                    .font(.settingsNote)
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

    /// One control over two stored values. Keeping the delay separate from
    /// the on/off state means switching back on restores the wait that was
    /// chosen before, rather than dropping back to the default.
    private var autoTranslateSelection: Binding<Int> {
        Binding(
            get: { settings.autoTranslate ? settings.autoTranslateDelayMs : Self.offTag },
            set: { selected in
                if selected == Self.offTag {
                    settings.autoTranslate = false
                } else {
                    settings.autoTranslateDelayMs = selected
                    settings.autoTranslate = true
                }
            }
        )
    }

    private static func delayLabel(_ milliseconds: Int) -> String {
        let value: String
        if milliseconds >= 1000 {
            let seconds = Double(milliseconds) / 1000
            value = seconds == seconds.rounded()
                ? "\(Int(seconds)) s"
                : String(format: "%.1f s", seconds)
        } else {
            value = "\(milliseconds) ms"
        }
        return String(localized: "After \(value)")
    }
}

#Preview {
    TranslationSettingsPane()
        .environmentObject(AppSettings())
}
