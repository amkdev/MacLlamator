//
//  OllamaSettingsPane.swift
//  MacLlamator
//

import SwiftUI

/// Everything about reaching the server and picking a model — the half of
/// Settings that says *where* translation happens, as opposed to *how*.
struct OllamaSettingsPane: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var catalog: ModelCatalog

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SettingsSection("Ollama Server") {
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

                Divider()

                HStack {
                    Text("Keep model in memory")
                    Spacer()
                    Picker("Keep model in memory", selection: $settings.keepAliveSeconds) {
                        ForEach(AppSettings.keepAliveOptions, id: \.self) { seconds in
                            Text(Self.keepAliveLabel(seconds)).tag(seconds)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 160)
                }

                Text("Ollama unloads a model after five minutes by default, and the next translation then waits for it to be reloaded. A longer setting keeps it resident at the cost of the memory it occupies.")
                    .font(.settingsNote)
                    .foregroundStyle(.secondary)
            }

            SettingsSection("Model") {
                Picker("Model", selection: $settings.model) {
                    if settings.model.isEmpty {
                        Text("No model selected").tag("")
                    }
                    ForEach(catalog.models) { model in
                        Text(model.name).tag(model.name)
                    }
                }
                .labelsHidden()

                Divider()

                HStack {
                    Button {
                        Task { await catalog.refresh(settings: settings) }
                    } label: {
                        if catalog.isLoading {
                            ProgressView().controlSize(.small)
                        } else {
                            Label("Refresh models", systemImage: "arrow.clockwise")
                        }
                    }
                    .disabled(catalog.isLoading)

                    if let connectionError = catalog.errorMessage {
                        Text(connectionError)
                            .font(.settingsNote)
                            .foregroundStyle(.red)
                    }
                }
            }
        }
        .settingsPaneLayout()
        .task { await catalog.refresh(settings: settings) }
        // Pointing the app at a different server invalidates the list that is
        // on screen, so it is re-read rather than left showing the old one.
        .onChange(of: settings.useLocal) { _, _ in reloadModels() }
        .onChange(of: settings.host) { _, _ in reloadModels() }
        .onChange(of: settings.port) { _, _ in reloadModels() }
    }

    private func reloadModels() {
        Task { await catalog.refresh(settings: settings) }
    }

    private static func keepAliveLabel(_ seconds: Int) -> String {
        switch seconds {
        case -1:   return String(localized: "Until Ollama quits")
        case 300:  return String(localized: "5 minutes")
        case 1800: return String(localized: "30 minutes")
        case 3600: return String(localized: "1 hour")
        default:   return "\(seconds) s"
        }
    }
}

#Preview {
    OllamaSettingsPane()
        .environmentObject(AppSettings())
        .environmentObject(ModelCatalog())
}
