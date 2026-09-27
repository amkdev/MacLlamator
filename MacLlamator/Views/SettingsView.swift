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
            section("Ollama Server") {
                Toggle("Local server (127.0.0.1)", isOn: $settings.useLocal)

                if !settings.useLocal {
                    Divider()
                    TextField("Host or IP address", text: $settings.host)
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

            section("Model") {
                Picker("Model", selection: $settings.model) {
                    if settings.model.isEmpty {
                        Text("No model selected").tag("")
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
                            Label("Refresh models", systemImage: "arrow.clockwise")
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

            section("Preferred languages") {
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

            section("Prompt") {
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
