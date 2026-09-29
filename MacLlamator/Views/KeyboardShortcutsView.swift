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
        /// Split into single keys so each can be drawn as its own cap, the
        /// way a keyboard shows them.
        let keys: [String]
        let action: LocalizedStringKey
        var id: String { keys.joined() }
    }

    private static let shortcuts: [Shortcut] = [
        Shortcut(keys: ["⌘", "↩"], action: "Translate now"),
        Shortcut(keys: ["⇧", "⌘", "S"], action: "Swap source and target language"),
        Shortcut(keys: ["⌘", "+"], action: "Increase text size"),
        Shortcut(keys: ["⌘", "−"], action: "Decrease text size"),
        Shortcut(keys: ["⌘", ","], action: "Open Settings"),
        Shortcut(keys: ["⌘", "W"], action: "Hide the window; the menu bar icon brings it back"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // No heading here: the window title already says what this is.
            VStack(alignment: .leading, spacing: 12) {
                ForEach(Self.shortcuts) { shortcut in
                    HStack(alignment: .firstTextBaseline, spacing: 16) {
                        keyCaps(shortcut.keys)
                        Text(shortcut.action)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 0)
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(nsColor: .controlBackgroundColor))
            }

            Text("Translating and swapping are also in the Translation menu, which is where macOS shows their shortcuts.")
                .font(.settingsNote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .frame(width: 460)
        .fixedSize(horizontal: false, vertical: true)
    }

    /// Each key drawn as its own cap. A monospaced font was the first
    /// attempt at lining the column up, but ⌘, ⇧ and ↩ are thin and poorly
    /// drawn in monospaced faces — caps of a fixed width align just as well
    /// and let the symbols keep the system font they were designed for.
    private func keyCaps(_ keys: [String]) -> some View {
        HStack(spacing: 4) {
            ForEach(keys, id: \.self) { key in
                Text(key)
                    .font(.system(size: 14, weight: .medium))
                    .frame(minWidth: 26, minHeight: 24)
                    .background {
                        RoundedRectangle(cornerRadius: 5)
                            .fill(Color.primary.opacity(0.08))
                            .overlay {
                                RoundedRectangle(cornerRadius: 5)
                                    .stroke(Color.primary.opacity(0.15), lineWidth: 1)
                            }
                    }
            }
        }
        // Reserves the width of the widest combination so the descriptions
        // start on one line regardless of how many keys a row has.
        .frame(width: 92, alignment: .leading)
    }
}

#Preview {
    KeyboardShortcutsView()
}
