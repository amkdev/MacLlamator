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

    @StateObject private var settings = OllamaSettings()
    @StateObject private var fontSettings = EditorFontSettings()

    var body: some Scene {
        WindowGroup(id: "main") {
            ContentView()
                .environmentObject(settings)
                .environmentObject(fontSettings)
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
        }
        .windowResizability(.contentSize)
    }
}
