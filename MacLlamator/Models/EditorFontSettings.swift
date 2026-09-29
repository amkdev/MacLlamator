//
//  EditorFontSettings.swift
//  MacLlamator
//

import Foundation
import Combine

/// Shared font size for the source/translation text panes, adjustable via
/// Cmd+Plus / Cmd+Minus and persisted across launches.
final class EditorFontSettings: ObservableObject {
    static let defaultSize: Double = 18
    static let minSize: Double = 12
    static let maxSize: Double = 32
    private static let step: Double = 2

    /// Extra space between lines, as a share of the font size. Proportional
    /// rather than a fixed number of points so the panes stay equally airy
    /// across the whole 12-to-32-point range, instead of looking cramped at
    /// the top of it and loose at the bottom.
    private static let lineSpacingRatio: Double = 0.22

    @Published var size: Double {
        didSet { UserDefaults.standard.set(size, forKey: Keys.size) }
    }

    private enum Keys {
        static let size = "editor.fontSize"
    }

    init() {
        let stored = UserDefaults.standard.object(forKey: Keys.size) as? Double
        self.size = stored ?? Self.defaultSize
    }

    /// Point value handed to the text panes' paragraph style.
    var lineSpacing: Double { size * Self.lineSpacingRatio }

    func increase() {
        size = min(Self.maxSize, size + Self.step)
    }

    func decrease() {
        size = max(Self.minSize, size - Self.step)
    }
}
