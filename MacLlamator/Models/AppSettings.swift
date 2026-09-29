//
//  AppSettings.swift
//  MacLlamator
//

import Foundation
import Combine

/// Everything the app remembers between launches: the Ollama connection and
/// the chosen model, the two preferred languages, and the extra prompt
/// instructions.
///
/// Persisted in UserDefaults. The keys keep their historical `ollama.` prefix
/// even though the type is no longer Ollama-specific, so that existing
/// installations keep their settings across the rename.
final class AppSettings: ObservableObject {
    @Published var useLocal: Bool {
        didSet { UserDefaults.standard.set(useLocal, forKey: Keys.useLocal) }
    }

    @Published var host: String {
        didSet { UserDefaults.standard.set(host, forKey: Keys.host) }
    }

    @Published var port: Int {
        didSet { UserDefaults.standard.set(port, forKey: Keys.port) }
    }

    @Published var model: String {
        didSet { UserDefaults.standard.set(model, forKey: Keys.model) }
    }

    /// Free-form text appended to the translation prompt, e.g. to steer
    /// tone, terminology, or work around a specific model's quirks.
    @Published var customInstructions: String {
        didSet { UserDefaults.standard.set(customInstructions, forKey: Keys.customInstructions) }
    }

    /// How long Ollama should keep the model in memory after a request, in
    /// seconds; `-1` keeps it loaded until Ollama itself exits. Ollama's own
    /// default is 300 seconds, after which the next translation waits for the
    /// model to be reloaded. Must be sent as a number — the string "-1" is
    /// rejected with HTTP 400.
    @Published var keepAliveSeconds: Int {
        didSet { UserDefaults.standard.set(keepAliveSeconds, forKey: Keys.keepAliveSeconds) }
    }

    /// The two languages (as ISO codes) between which auto-detection should
    /// automatically flip the target language: detecting one of them selects
    /// the other as the target.
    @Published var preferredLanguageA: String {
        didSet { UserDefaults.standard.set(preferredLanguageA, forKey: Keys.preferredLanguageA) }
    }

    @Published var preferredLanguageB: String {
        didSet { UserDefaults.standard.set(preferredLanguageB, forKey: Keys.preferredLanguageB) }
    }

    private enum Keys {
        static let useLocal = "ollama.useLocal"
        static let host = "ollama.host"
        static let port = "ollama.port"
        static let model = "ollama.model"
        static let customInstructions = "ollama.customInstructions"
        static let preferredLanguageA = "ollama.preferredLanguageA"
        static let preferredLanguageB = "ollama.preferredLanguageB"
        static let keepAliveSeconds = "ollama.keepAliveSeconds"
    }

    init() {
        let defaults = UserDefaults.standard
        self.useLocal = defaults.object(forKey: Keys.useLocal) as? Bool ?? true
        self.host = defaults.string(forKey: Keys.host) ?? "127.0.0.1"
        self.port = defaults.object(forKey: Keys.port) as? Int ?? 11434
        self.model = defaults.string(forKey: Keys.model) ?? ""
        self.customInstructions = defaults.string(forKey: Keys.customInstructions) ?? ""
        self.preferredLanguageA = defaults.string(forKey: Keys.preferredLanguageA) ?? "de"
        self.preferredLanguageB = defaults.string(forKey: Keys.preferredLanguageB) ?? "en"
        self.keepAliveSeconds = defaults.object(forKey: Keys.keepAliveSeconds) as? Int ?? 1800
    }

    /// Offered in Settings. Seconds, with `-1` meaning "until Ollama exits".
    static let keepAliveOptions: [Int] = [300, 1800, 3600, -1]

    /// Base URL of the Ollama server, respecting the "local" toggle.
    var baseURL: URL? {
        let effectiveHost = useLocal ? "127.0.0.1" : host
        guard !effectiveHost.isEmpty else { return nil }
        return URL(string: "http://\(effectiveHost):\(port)")
    }
}
