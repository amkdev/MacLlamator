//
//  SettingsSection.swift
//  MacLlamator
//

import SwiftUI

/// A titled, rounded group of controls — the building block both settings
/// panes are made of. Lives on its own so the two panes stay visually
/// identical without one of them owning the other's layout.
struct SettingsSection<Content: View>: View {
    let title: LocalizedStringKey
    @ViewBuilder let content: Content

    init(_ title: LocalizedStringKey, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)

            VStack(alignment: .leading, spacing: 12) {
                content
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(nsColor: .controlBackgroundColor))
            }
        }
    }
}

extension Font {
    /// The explanatory text under a setting.
    ///
    /// Defined once because it appears in every pane, and it started out as
    /// `.caption` — ten points, which is a footnote size and was genuinely
    /// hard to read. `.callout` is two points larger and still clearly
    /// subordinate to the thirteen-point body text it explains.
    static let settingsNote = Font.callout
}

/// Shared geometry for the panes, so switching tabs does not change the
/// window's width.
extension View {
    func settingsPaneLayout() -> some View {
        self
            .padding(20)
            .frame(width: 420)
            .fixedSize(horizontal: false, vertical: true)
    }
}
