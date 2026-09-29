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

    /// Grouped roughly by region rather than sorted, because the menu shows
    /// them in this order and the names are localized — an alphabetical list
    /// would reshuffle itself with the system language.
    static let all: [Language] = [
        "de", "en", "fr", "es", "it", "pt", "nl", "pl", "ru", "tr",
        "sv", "da", "no", "fi", "cs", "uk", "ro", "el",
        "ja", "ko", "zh", "vi", "id", "hi",
        "ar", "he", "fa",
    ].map(Language.init(code:))

    /// The catalogue's codes as a set, for narrowing a model's declaration
    /// down to languages this app actually offers.
    static let allCodes: Set<String> = Set(all.map(\.code))

    // The source column additionally offers automatic detection, but which
    // languages are listed at all is now the user's choice — see
    // AppSettings.enabledLanguages.
}
