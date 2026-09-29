//
//  ModelCatalog.swift
//  MacLlamator
//

import Foundation
import Combine

/// The models the Ollama server currently offers.
///
/// Shared by the toolbar's model menu and the settings pane rather than
/// fetched by each of them: the two would otherwise disagree after one of
/// them refreshed, and the server would be asked twice for the same list.
@MainActor
final class ModelCatalog: ObservableObject {
    @Published private(set) var models: [OllamaModel] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    /// What each model says about its own languages, keyed by model name.
    /// An empty set means "asked, and it makes no claim" — remembered so the
    /// server is not asked again every time Settings is opened.
    @Published private(set) var declaredLanguages: [String: Set<String>] = [:]

    private let service = OllamaService()

    /// Re-reads the model list. A failure leaves the previous list standing
    /// instead of emptying it — a server that is briefly unreachable should
    /// not make the toolbar menu collapse — and is reported separately.
    func refresh(settings: AppSettings) async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            models = try await service.fetchModels(settings: settings)
            // A fresh install has no model selected yet. Picking the first
            // one means the app translates straight away instead of greeting
            // the user with "no model selected".
            if settings.model.isEmpty, let first = models.first {
                settings.model = first.name
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Reads a model's own language declaration once and keeps it.
    func refreshDeclaredLanguages(for model: String, settings: AppSettings) async {
        guard !model.isEmpty, declaredLanguages[model] == nil else { return }

        let declared: Set<String>?
        do {
            declared = try await service.declaredLanguageCodes(model: model, settings: settings)
        } catch {
            // A model that cannot be reached has not said anything either;
            // it just has not said it yet, so nothing is cached.
            return
        }
        declaredLanguages[model] = declared ?? []
    }

    /// The languages a model claims to handle: its own declaration where the
    /// model file carries one, our hand-kept table where it does not, and
    /// `nil` when neither has anything to say — in which case nothing should
    /// be suggested at all.
    func claimedLanguageCodes(for model: String) -> Set<String>? {
        if let declared = declaredLanguages[model], !declared.isEmpty {
            return declared
        }
        return ModelLanguageSupport.supportedCodes(forModel: model)
    }
}
