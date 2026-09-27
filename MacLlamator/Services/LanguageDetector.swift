//
//  LanguageDetector.swift
//  MacLlamator
//

import Foundation
import NaturalLanguage

/// On-device source-language detection, used instead of asking the model to
/// identify the language as part of the translation request.
///
/// Splitting the two jobs matters for reliability: some models answer the
/// combined "identify the language and translate" prompt by reporting the
/// language correctly and then echoing the source text back instead of
/// translating it. Detecting here means the model only ever receives the
/// single-task prompt, which every model tested handles correctly.
///
/// It is also free and instant, so detection can run on every keystroke
/// rather than once per session.
enum LanguageDetector {

    /// Hypotheses below this confidence are reported as "unknown" rather than
    /// guessed at. Measured against `NLLanguageRecognizer`: a three-word
    /// fragment already scores 1.0, while isolated ambiguous words fall far
    /// below — "Test" 0.16, "Rat" 0.23, "Information" 0.39, and "Hi" was
    /// confidently wrong at 0.50.
    static let minimumConfidence: Double = 0.65

    /// Detection saturates long before this, so only the opening of a long
    /// text is examined. Keeps the cost per keystroke flat no matter how much
    /// text the pane holds.
    static let sampleLimit = 1_000

    /// Attempts to identify the language of `text`.
    ///
    /// Returns `nil` when the text is too short or too ambiguous to call, so
    /// callers can hold on to a previous result instead of acting on a guess.
    static func detect(_ text: String) -> Language? {
        let sample = String(
            text.trimmingCharacters(in: .whitespacesAndNewlines).prefix(sampleLimit)
        )
        guard sample.count >= 2 else { return nil }

        let recognizer = NLLanguageRecognizer()
        recognizer.languageConstraints = Self.constraints
        recognizer.processString(sample)

        guard let dominant = recognizer.dominantLanguage else { return nil }
        let confidence = recognizer.languageHypotheses(withMaximum: 1)[dominant] ?? 0
        guard confidence >= minimumConfidence else { return nil }

        guard let code = Self.appCode(for: dominant.rawValue) else { return nil }
        return Language.all.first { $0.code == code }
    }

    // MARK: - Code mapping

    // `NLLanguage` does not use the same codes the app does throughout, and
    // constraining the recognizer to codes it does not know is worse than not
    // constraining it at all: with "zh" in the list and "zh-Hans" missing,
    // Chinese input was identified as Japanese with a confidence of 1.0,
    // because the correct answer had been excluded. Hence the explicit
    // translation in both directions.

    private static let constraints: [NLLanguage] =
        Language.all.flatMap { Self.nlCodes(for: $0.code) }.map { NLLanguage(rawValue: $0) }

    private static func nlCodes(for appCode: String) -> [String] {
        switch appCode {
        case "no": return ["nb", "nn"]          // Bokmål and Nynorsk
        case "zh": return ["zh-Hans", "zh-Hant"] // Simplified and Traditional
        default: return [appCode]
        }
    }

    private static func appCode(for nlCode: String) -> String? {
        switch nlCode {
        case "nb", "nn": return "no"
        case "zh-Hans", "zh-Hant": return "zh"
        default: return Language.all.contains { $0.code == nlCode } ? nlCode : nil
        }
    }
}
