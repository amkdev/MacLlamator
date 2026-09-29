//
//  MacLlamatorApp.swift
//  MacLlamator
//
//  Created by Administrator on 24.09.26.
//

import SwiftUI

@main
struct MacLlamatorApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    @StateObject private var settings = AppSettings()
    @StateObject private var fontSettings = EditorFontSettings()
    @StateObject private var modelCatalog = ModelCatalog()

    var body: some Scene {
        WindowGroup(id: "main") {
            ContentView()
                .environmentObject(settings)
                .environmentObject(fontSettings)
                .environmentObject(modelCatalog)
        }
        .commands {
            CommandMenu("Font") {
                Button("Larger") { fontSettings.increase() }
                    .keyboardShortcut("+", modifiers: .command)
                Button("Smaller") { fontSettings.decrease() }
                    .keyboardShortcut("-", modifiers: .command)
            }
        }

        Settings {
            SettingsView()
                .environmentObject(settings)
                .environmentObject(modelCatalog)
        }
        .windowResizability(.contentSize)
    }
}
