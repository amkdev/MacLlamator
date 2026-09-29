//
//  SettingsView.swift
//  MacLlamator
//

import SwiftUI

/// The Settings window: three tabs along the lines the settings themselves
/// fall on — where translation runs, which languages it offers, and how it
/// behaves. Languages earn a page of their own because the list of ticks is
/// tall enough to bury whatever shares a column with it.
struct SettingsView: View {
    var body: some View {
        TabView {
            OllamaSettingsPane()
                .tabItem { Label("Ollama", systemImage: "server.rack") }

            LanguageSettingsPane()
                .tabItem { Label("Languages", systemImage: "globe") }

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
