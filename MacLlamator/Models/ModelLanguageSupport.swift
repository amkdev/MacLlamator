//
//  ModelLanguageSupport.swift
//  MacLlamator
//

import Foundation

/// Which languages a model's makers say it handles.
///
/// This table is written by hand because there is nothing to read it from.
/// The GGUF behind `aya:latest` carries three `general.` keys —
/// architecture, name, file type — and no language list; Ollama's
/// `/api/show` passes through even less, with no key mentioning a language
/// at all. The one machine-readable list lives in the Hugging Face model
/// card's front matter, which is behind an access gate for Aya and missing
/// entirely for models published only to Ollama. Anyone looking for the
/// automatic solution later can stop looking: there isn't one.
///
/// The table is deliberately advisory. A language missing from it is
/// flagged, never hidden: "not on the official list" is not "cannot do it",
/// and Aya very likely produces passable Swedish — Cohere simply does not
/// stand behind it. A model the table does not know returns `nil`, and then
/// nothing is flagged at all, which is the right answer for a guess.
enum ModelLanguageSupport {

    /// The ISO codes a model officially covers, or `nil` if this table has
    /// never heard of it.
    static func supportedCodes(forModel model: String) -> Set<String>? {
        let name = model.lowercased()
        return table.first { name.hasPrefix($0.prefix) }?.codes
    }

    /// True only when the model is known *and* leaves this language out.
    /// Automatic detection is never flagged — there is no language to judge
    /// until it has settled on one.
    static func isUnsupported(_ language: Language, by model: String) -> Bool {
        guard !language.isAuto else { return false }
        guard let codes = supportedCodes(forModel: model) else { return false }
        return !codes.contains(language.code)
    }

    private struct Entry {
        let prefix: String
        let codes: Set<String>
    }

    /// Matched against the start of the model name, so `aya:latest` and
    /// `aya-expanse:8b` both find the Aya row. Add a model here only once
    /// its published list has actually been read — an invented row is worse
    /// than no row, because it warns about languages that work and stays
    /// silent about ones that do not.
    private static let table: [Entry] = [
        // Aya 23, per Cohere's model card: 23 languages.
        Entry(prefix: "aya", codes: [
            "ar", "zh", "cs", "nl", "en", "fr", "de", "el", "he", "hi", "id",
            "it", "ja", "ko", "fa", "pl", "pt", "ro", "ru", "es", "tr", "uk", "vi",
        ]),
    ]
}
