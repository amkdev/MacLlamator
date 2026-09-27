//
//  Language.swift
//  MacLlamator
//

import Foundation

struct Language: Identifiable, Hashable, Codable {
    let code: String

    var id: String { code }

    /// Pseudo-language representing automatic source-language detection.
    static let auto = Language(code: "auto")

    var isAuto: Bool { code == Self.auto.code }

    /// Name shown in the interface, in whatever language the system is set to.
    /// Derived from the system's own language database rather than a hardcoded
    /// table, so the picker follows the user's locale for free.
    var displayName: String {
        if isAuto { return String(localized: "Detect language") }
        return Locale.current.localizedString(forLanguageCode: code)?.localizedCapitalized
            ?? code.uppercased()
    }

    /// Always-English name, used inside the prompt sent to the model. Keeping
    /// this independent of the system language means translation quality does
    /// not change just because the interface is running in German.
    var englishName: String {
        Locale(identifier: "en_US").localizedString(forLanguageCode: code)?.capitalized
            ?? code.uppercased()
    }

    static let all: [Language] = [
        "de", "en", "fr", "es", "it", "pt", "nl", "pl", "ru", "tr",
        "sv", "da", "no", "fi", "cs", "uk", "ja", "ko", "zh", "ar",
    ].map(Language.init(code:))

    /// Source column may additionally offer automatic detection.
    static let sourceOptions: [Language] = [.auto] + all
}
