//
//  ModelLanguageSupport.swift
//  MacLlamator
//

import Foundation

/// Language lists for models whose own files do not carry one.
///
/// The first place to look is the model itself: `/api/show` exposes
/// `general.languages` where the GGUF carries it, and that is the
/// publisher's own declaration — see `OllamaService.declaredLanguageCodes`.
/// This table is only the patch list for models that stay silent, and that
/// split runs right through the two models this app was built against:
/// `llama3.1:8b` declares Meta's eight languages, `aya:latest` has no
/// language key at all.
///
/// Both sources only ever advise. They feed the suggestion in Settings that
/// narrows the language list to what a model is built for; nothing is hidden
/// or blocked on their say-so, because "not on the published list" is not
/// "cannot do it" — Aya very likely manages Swedish, Cohere simply does not
/// stand behind it. What appears in the pickers is the user's own choice.
///
/// Add a model here only once its published list has really been read. An
/// invented row is worse than no row: it recommends against languages that
/// work and stays quiet about ones that do not.
enum ModelLanguageSupport {

    /// The ISO codes a model officially covers, or `nil` if this table has
    /// never heard of it.
    static func supportedCodes(forModel model: String) -> Set<String>? {
        let name = model.lowercased()
        return table.first { name.hasPrefix($0.prefix) }?.codes
    }

    private struct Entry {
        let prefix: String
        let codes: Set<String>
    }

    /// Matched against the start of the model name, so `aya:latest` and
    /// `aya-expanse:8b` both find the Aya row.
    private static let table: [Entry] = [
        // Aya 23, per Cohere's model card: 23 languages.
        Entry(prefix: "aya", codes: [
            "ar", "zh", "cs", "nl", "en", "fr", "de", "el", "he", "hi", "id",
            "it", "ja", "ko", "fa", "pl", "pt", "ro", "ru", "es", "tr", "uk", "vi",
        ]),
    ]
}
