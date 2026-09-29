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
    @Environment(\.openWindow) private var openWindow

    // Published by whichever window is in front, so the menu can drive the
    // translator without the translation state having to leave ContentView.
    @FocusedValue(\.translateNow) private var translateNow
    @FocusedValue(\.swapLanguages) private var swapLanguages

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
            CommandMenu("Translation") {
                Button("Translate now") { translateNow?() }
                    .keyboardShortcut(.return, modifiers: .command)
                    .disabled(translateNow == nil)

                Button("Swap source and target language") { swapLanguages?() }
                    .keyboardShortcut("s", modifiers: [.command, .shift])
                    .disabled(swapLanguages == nil)
            }

            CommandMenu("Font") {
                Button("Larger") { fontSettings.increase() }
                    .keyboardShortcut("+", modifiers: .command)
                Button("Smaller") { fontSettings.decrease() }
                    .keyboardShortcut("-", modifiers: .command)
            }

            // The stock Help entry opens a help book this app does not ship,
            // which fails with a dialog. A list of shortcuts is both honest
            // and the thing someone opening Help here is likely after.
            CommandGroup(replacing: .help) {
                Button("Keyboard shortcuts") {
                    openWindow(id: Self.shortcutsWindowID)
                }
            }
        }

        Window("Keyboard shortcuts", id: Self.shortcutsWindowID) {
            KeyboardShortcutsView()
        }
        .windowResizability(.contentSize)

        Settings {
            SettingsView()
                .environmentObject(settings)
                .environmentObject(modelCatalog)
        }
        .windowResizability(.contentSize)
    }

    private static let shortcutsWindowID = "keyboard-shortcuts"
}
