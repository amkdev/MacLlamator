//
//  SettingsView.swift
//  MacLlamator
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settings: OllamaSettings
    private let service = OllamaService()

    @State private var availableModels: [OllamaModel] = []
    @State private var isLoadingModels = false
    @State private var connectionError: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            section("Ollama-Server") {
                Toggle("Lokaler Server (127.0.0.1)", isOn: $settings.useLocal)

                if !settings.useLocal {
                    Divider()
                    TextField("Host oder IP-Adresse", text: $settings.host)
                        .textFieldStyle(.roundedBorder)
                        .disableAutocorrection(true)
                }

                Divider()

                HStack {
                    Text("Port")
                    Spacer()
                    TextField(
                        "Port",
                        value: $settings.port,
                        format: .number.grouping(.never)
                    )
                    .labelsHidden()
                    .textFieldStyle(.roundedBorder)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 120)
                }
            }

            section("Modell") {
                Picker("Modell", selection: $settings.model) {
                    if settings.model.isEmpty {
                        Text("Kein Modell ausgewählt").tag("")
                    }
                    ForEach(availableModels) { model in
                        Text(model.name).tag(model.name)
                    }
                }
                .labelsHidden()

                Divider()

                HStack {
                    Button {
                        Task { await loadModels() }
                    } label: {
                        if isLoadingModels {
                            ProgressView().controlSize(.small)
                        } else {
                            Label("Modelle aktualisieren", systemImage: "arrow.clockwise")
                        }
                    }
                    .disabled(isLoadingModels)

                    if let connectionError {
                        Text(connectionError)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }

            section("Bevorzugte Sprachen") {
                Text("Erkennt die automatische Spracherkennung eine dieser beiden Sprachen, wird jeweils die andere als Zielsprache gewählt.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack {
                    Text("Sprache 1")
                    Spacer()
                    Picker("Sprache 1", selection: $settings.preferredLanguageA) {
                        ForEach(Language.all) { language in
                            Text(language.name).tag(language.code)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 160)
                }

                Divider()

                HStack {
                    Text("Sprache 2")
                    Spacer()
                    Picker("Sprache 2", selection: $settings.preferredLanguageB) {
                        ForEach(Language.all) { language in
                            Text(language.name).tag(language.code)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 160)
                }
            }

            section("Prompt") {
                Text("Zusätzliche Anweisungen an das Modell (optional), z. B. zu Tonalität oder Terminologie.")
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
                    Button("Zurücksetzen") {
                        settings.customInstructions = ""
                    }
                    .disabled(settings.customInstructions.isEmpty)
                }
            }
        }
        .padding(20)
        .frame(width: 420)
        .fixedSize(horizontal: false, vertical: true)
        .task { await loadModels() }
    }

    @ViewBuilder
    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)

            VStack(alignment: .leading, spacing: 12) {
                content()
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(nsColor: .controlBackgroundColor))
            }
        }
    }

    private func loadModels() async {
        isLoadingModels = true
        connectionError = nil
        defer { isLoadingModels = false }

        do {
            availableModels = try await service.fetchModels(settings: settings)
            if settings.model.isEmpty, let first = availableModels.first {
                settings.model = first.name
            }
        } catch {
            connectionError = error.localizedDescription
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(OllamaSettings())
}
