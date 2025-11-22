//
//  SearchViewModel.swift
//  NetflixWatchlist
//
//  Created by Kyle Mooney on 1/30/25.
//

import Foundation
import CoreData

// Explicit detail source type kept alongside the view model so both
// SearchViewModel and the UI can reference it without scoping issues.
enum DetailSource {
    case search
    case watchlist
}

class SearchViewModel: ObservableObject {
    @Published var remainingApiCalls: Int = 0
    @Published var searchResults: [CatalogItem] = []
    @Published var errorMessage: String?
    @Published var selectedAvailability: [CountryAvailability] = []
    @Published var savedItems: [SavedCatalogItem] = []
    @Published var pendingSavedItemIDs: Set<String> = []

    private var availabilityCache: [String: [CountryAvailability]] = [:]

    private let service = UnogsService()
    private let coreDataManager = CoreDataManager.shared

    // ✅ Needed for all your availabilityCache lookups
    private var availabilityCache: [String: [CountryAvailability]] = [:]

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
    }

    func fetchAvailability(
        for catalogItem: CatalogItem,
        source: DetailSource = .search
    ) {
        let itemId = catalogItem.itemId
        let shouldUseSavedData = source == .watchlist

        if shouldUseSavedData {
            let savedAvailability = catalogItem.availability
                ?? availabilityCache[itemId]
                ?? []

            if !savedAvailability.isEmpty {
                availabilityCache[itemId] = savedAvailability
            }

            DispatchQueue.main.async {
                self.selectedAvailability = savedAvailability
            }
            return
        }

        if let cachedAvailability = availabilityCache[itemId], !cachedAvailability.isEmpty {
            DispatchQueue.main.async {
                self.selectedAvailability = cachedAvailability
            }
        } else if let embeddedAvailability = catalogItem.availability, !embeddedAvailability.isEmpty {
            availabilityCache[itemId] = embeddedAvailability

            DispatchQueue.main.async {
                self.selectedAvailability = embeddedAvailability
            }
        }

        service.fetchCatalogItemAvailability(itemId: itemId, countTowardsUsage: true) { [weak self] availability in
            guard let self = self else { return }

            self.availabilityCache[itemId] = availability

            DispatchQueue.main.async {
                self.selectedAvailability = availability
                self.remainingApiCalls = self.service.remainingApiCalls()
                self.updateSearchResultAvailability(itemId: itemId, availability: availability)
            }

            // Cache for later use (e.g., saving to watchlist)
            self.availabilityCache[catalogItem.itemId] = availability
        }
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

    private func refreshSavedFlags() {
        guard !savedItems.isEmpty else { return }
        let savedIDs = Set(savedItems.compactMap { $0.itemId })

        searchResults = searchResults.map { item in
            guard savedIDs.contains(item.itemId) else { return item }
            var updated = item
            updated.isSavedItem = true
            if updated.availability == nil, let cached = availabilityCache[item.itemId] {
                updated.availability = cached
            }
            return updated
        }
    }

    private func updateSearchResultAvailability(itemId: String, availability: [CountryAvailability]) {
        guard !availability.isEmpty else { return }

        searchResults = searchResults.map { item in
            guard item.itemId == itemId else { return item }

            var updatedItem = item
            updatedItem.availability = availability
            return updatedItem
        }
    }
}
