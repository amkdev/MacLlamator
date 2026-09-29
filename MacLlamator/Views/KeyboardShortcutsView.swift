//
//  KeyboardShortcutsView.swift
//  MacLlamator
//

import SwiftUI

/// The one place that lists every shortcut at once.
///
/// The menu bar already names each one beside its command, which is where a
/// Mac user looks first — but only for commands that have a menu entry.
/// Closing the window and opening Settings do not, and nobody hunts through
/// the system menus to find out what an app added. So the Help menu keeps a
/// full list, which is also what someone reaches for when they want to learn
/// the app rather than look one thing up.
struct KeyboardShortcutsView: View {
    private struct Shortcut: Identifiable {
        let keys: String
        let action: LocalizedStringKey
        var id: String { keys }
    }

    private static let shortcuts: [Shortcut] = [
        Shortcut(keys: "⌘↩", action: "Translate now"),
        Shortcut(keys: "⇧⌘S", action: "Swap source and target language"),
        Shortcut(keys: "⌘+", action: "Increase text size"),
        Shortcut(keys: "⌘−", action: "Decrease text size"),
        Shortcut(keys: "⌘,", action: "Open Settings"),
        Shortcut(keys: "⌘W", action: "Hide the window; the menu bar icon brings it back"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Keyboard shortcuts")
                .font(.headline)

            VStack(alignment: .leading, spacing: 10) {
                ForEach(Self.shortcuts) { shortcut in
                    HStack(alignment: .firstTextBaseline, spacing: 16) {
                        Text(shortcut.keys)
                            // Fixed width and a monospaced face so the
                            // symbols line up into a column instead of
                            // stepping in and out with their own widths.
                            .font(.system(.body, design: .monospaced))
                            .frame(width: 54, alignment: .leading)
                        Text(shortcut.action)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 0)
                    }
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(nsColor: .controlBackgroundColor))
            }

            Text("Translating and swapping are also in the Translation menu, which is where macOS shows their shortcuts.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .frame(width: 420)
        .fixedSize(horizontal: false, vertical: true)
    }
}

#Preview {
    KeyboardShortcutsView()
}
