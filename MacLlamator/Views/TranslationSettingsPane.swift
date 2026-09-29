//
//  TranslationSettingsPane.swift
//  MacLlamator
//

import SwiftUI

/// How translation behaves — how eagerly it runs, and what the model is told
/// beyond the text. Which languages exist is the language pane's business,
/// and where it runs is Ollama's.
struct TranslationSettingsPane: View {
    @EnvironmentObject private var settings: AppSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
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
}
