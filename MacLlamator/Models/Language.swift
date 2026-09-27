//
//  Language.swift
//  MacLlamator
//

import Foundation

struct Language: Identifiable, Hashable, Codable {
    let code: String
    let name: String

    var id: String { code }

    /// Pseudo-language representing automatic source-language detection.
    static let auto = Language(code: "auto", name: "Automatisch erkennen")

    static let all: [Language] = [
        Language(code: "de", name: "Deutsch"),
        Language(code: "en", name: "Englisch"),
        Language(code: "fr", name: "Französisch"),
        Language(code: "es", name: "Spanisch"),
        Language(code: "it", name: "Italienisch"),
        Language(code: "pt", name: "Portugiesisch"),
        Language(code: "nl", name: "Niederländisch"),
        Language(code: "pl", name: "Polnisch"),
        Language(code: "ru", name: "Russisch"),
        Language(code: "tr", name: "Türkisch"),
        Language(code: "sv", name: "Schwedisch"),
        Language(code: "da", name: "Dänisch"),
        Language(code: "no", name: "Norwegisch"),
        Language(code: "fi", name: "Finnisch"),
        Language(code: "cs", name: "Tschechisch"),
        Language(code: "uk", name: "Ukrainisch"),
        Language(code: "ja", name: "Japanisch"),
        Language(code: "ko", name: "Koreanisch"),
        Language(code: "zh", name: "Chinesisch"),
        Language(code: "ar", name: "Arabisch"),
    ]

    /// Source column may additionally offer automatic detection.
    static let sourceOptions: [Language] = [.auto] + all
}
