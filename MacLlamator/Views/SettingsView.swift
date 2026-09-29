//
//  SettingsView.swift
//  MacLlamator
//

import SwiftUI

/// The Settings window: two tabs along the line the settings themselves
/// fall on — where translation runs, and how it behaves.
struct SettingsView: View {
    var body: some View {
        TabView {
            OllamaSettingsPane()
                .tabItem { Label("Ollama", systemImage: "server.rack") }

            TranslationSettingsPane()
                .tabItem { Label("Translation", systemImage: "character.bubble") }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppSettings())
        .environmentObject(ModelCatalog())
}
