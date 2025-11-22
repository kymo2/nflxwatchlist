//
//  SearchViewModel.swift
//  NetflixWatchlist
//
//  Created by Kyle Mooney on 1/30/25.
//

import Foundation
import CoreData

class SearchViewModel: ObservableObject {
    @Published var remainingApiCalls: Int = 0
    @Published var searchResults: [CatalogItem] = []
    @Published var errorMessage: String?
    @Published var selectedAvailability: [CountryAvailability] = []
    @Published var savedItems: [SavedCatalogItem] = []
    @Published var watchlistMessage: String?
    @Published var pendingSavedItemIDs: Set<String> = []

    private let service = UnogsService()
    private let coreDataManager = CoreDataManager.shared

    init() {
        fetchSavedItems()
        remainingApiCalls = service.remainingApiCalls()
    }

    func searchCatalog(title: String) {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            DispatchQueue.main.async {
                self.errorMessage = ""
                self.searchResults = []
            }
            return
        }

        DispatchQueue.main.async {
            self.searchResults = []
        }

        service.searchCatalogItems(title: trimmedTitle) { [weak self] result in
            guard let self = self else { return }

            DispatchQueue.main.async {
                switch result {
                case .success(let items):
                    self.searchResults = items
                    self.errorMessage = nil
                case .failure(let error):
                    switch error {
                    case .invalidURL:
                        self.errorMessage = "Invalid URL"
                    case .missingCredentials:
                        self.errorMessage = "Missing API credentials. Check API_KEY and API_HOST."
                    case .networkError(let message):
                        self.errorMessage = "Network error: \(message)"
                    case .emptyResults:
                        self.errorMessage = "No results found for \"\(trimmedTitle)\"."
                    case .decodingError(let message):
                        self.errorMessage = "Failed to process data: \(message)"
                    }
                }

                self.remainingApiCalls = self.service.remainingApiCalls()
                self.refreshSavedFlags()
            }
        }
        remainingApiCalls = service.remainingApiCalls()
    }

    func fetchAvailability(for catalogItem: CatalogItem) {
        if let cachedAvailability = catalogItem.availability, !cachedAvailability.isEmpty {
            DispatchQueue.main.async {
                self.selectedAvailability = cachedAvailability
            }
            return
        }

        // Do not trigger a network request or consume API counts for watchlist items
        if catalogItem.isSavedItem {
            DispatchQueue.main.async {
                self.selectedAvailability = catalogItem.availability ?? []
            }
            return
        }

        service.fetchCatalogItemAvailability(itemId: catalogItem.itemId, countTowardsUsage: true) { [weak self] availability in
            DispatchQueue.main.async {
                self?.selectedAvailability = availability
                self?.remainingApiCalls = self?.service.remainingApiCalls() ?? 0
            }
            return
        }
        remainingApiCalls = service.remainingApiCalls()
    }

    func saveToWatchlist(item: CatalogItem) {
        print("🌍 Preparing to save \(item.title) with cached availability")

        guard !isItemSaved(item) else {
            return
        }

        pendingSavedItemIDs.insert(item.itemId)

        service.fetchCatalogItemAvailability(itemId: item.itemId) { [weak self] availability in
            DispatchQueue.main.async {
                self.selectedAvailability = []
            }
            return
        }

        service.fetchCatalogItemAvailability(itemId: catalogItem.itemId, countTowardsUsage: true) { [weak self] availability in
            guard let self else { return }

            self.availabilityCache[catalogItem.itemId] = availability

                self?.coreDataManager.saveCatalogItem(item: item, availability: availability) // ✅ Save movie + country data
                self?.fetchSavedItems() // ✅ Refresh saved items after saving
                self?.pendingSavedItemIDs.remove(item.itemId)
                self?.watchlistMessage = "Added to watchlist"
            }
        }
        remainingApiCalls = service.remainingApiCalls()
    }

    func saveToWatchlist(item: CatalogItem) {
        print("🌍 Preparing to save \(item.title) with cached availability")

        guard !isItemSaved(item) else {
            return
        }

        pendingSavedItemIDs.insert(item.itemId)

        let cachedAvailability = item.availability
            ?? availabilityCache[item.itemId]
            ?? selectedAvailability

        coreDataManager.saveCatalogItem(item: item, availability: cachedAvailability)
        fetchSavedItems()
        pendingSavedItemIDs.remove(item.itemId)
    }

    func saveToWatchlist(item: CatalogItem) {
        print("🌍 Preparing to save \(item.title) with cached availability")

        guard !isItemSaved(item) else {
            return
        }

        pendingSavedItemIDs.insert(item.itemId)

        let cachedAvailability = item.availability
            ?? availabilityCache[item.itemId]
            ?? selectedAvailability

        coreDataManager.saveCatalogItem(item: item, availability: cachedAvailability)
        fetchSavedItems()
        pendingSavedItemIDs.remove(item.itemId)
    }

    func saveToWatchlist(item: CatalogItem) {
        guard !isItemSaved(item) else { return }

        pendingSavedItemIDs.insert(item.itemId)

        let cachedAvailability = item.availability
            ?? availabilityCache[item.itemId]
            ?? selectedAvailability

        coreDataManager.saveCatalogItem(item: item, availability: cachedAvailability)
        fetchSavedItems()
        pendingSavedItemIDs.remove(item.itemId)
    }

    func fetchSavedItems() {
        savedItems = coreDataManager.fetchSavedItems()
        let savedIDs = Set(savedItems.compactMap { $0.itemId })
        pendingSavedItemIDs.subtract(savedIDs)

        for saved in savedItems {
            if let itemAvailability = saved.toCatalogItem().availability, let itemId = saved.itemId {
                availabilityCache[itemId] = itemAvailability
            }
        }
    }

    func removeFromWatchlist(item: CatalogItem) {
        pendingSavedItemIDs.remove(item.itemId)
        coreDataManager.deleteSavedItem(itemId: item.itemId)
        fetchSavedItems()
    }

    func isItemSaved(_ item: CatalogItem) -> Bool {
        pendingSavedItemIDs.contains(item.itemId) || savedItems.contains(where: { $0.itemId == item.itemId })
    }
}
