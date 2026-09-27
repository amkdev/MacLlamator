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

    func increase() {
        size = min(Self.maxSize, size + Self.step)
    }

    func decrease() {
        size = max(Self.minSize, size - Self.step)
    }
}
