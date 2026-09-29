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
}
