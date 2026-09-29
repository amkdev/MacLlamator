//
//  SettingsView.swift
//  MacLlamator
//

import SwiftUI

/// The Settings window: three tabs along the lines the settings themselves
/// fall on — where translation runs, how it behaves, and which languages are
/// on offer. Languages come last and on a page of their own: the list of
/// ticks is tall enough to bury whatever shares a column with it, and it is
/// the page one visits once rather than often.
struct SettingsView: View {
    var body: some View {
        TabView {
            OllamaSettingsPane()
                .tabItem { Label("Ollama", systemImage: "server.rack") }

            TranslationSettingsPane()
                .tabItem { Label("Translation", systemImage: "character.bubble") }

            LanguageSettingsPane()
                .tabItem { Label("Languages", systemImage: "globe") }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppSettings())
        .environmentObject(ModelCatalog())
}
