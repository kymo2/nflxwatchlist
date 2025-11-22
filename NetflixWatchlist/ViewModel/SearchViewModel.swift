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
            }
        }

        // This is optional; keeps UI in sync immediately
        remainingApiCalls = service.remainingApiCalls()
    }

    func fetchAvailability(for catalogItem: CatalogItem) {
        // Use cached availability on the CatalogItem itself if present
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
            guard let self = self else { return }

            DispatchQueue.main.async {
                self.selectedAvailability = availability
                self.remainingApiCalls = self.service.remainingApiCalls()
            }

            // Cache for later use (e.g., saving to watchlist)
            self.availabilityCache[catalogItem.itemId] = availability
        }
    }

    // ✅ Single, clean implementation of saveToWatchlist
    func saveToWatchlist(item: CatalogItem) {
        guard !isItemSaved(item) else { return }

        pendingSavedItemIDs.insert(item.itemId)

        let cachedAvailability = item.availability
            ?? availabilityCache[item.itemId]
            ?? selectedAvailability

        DispatchQueue.main.async {
            self.coreDataManager.saveCatalogItem(item: item, availability: cachedAvailability)
            self.fetchSavedItems()
            self.pendingSavedItemIDs.remove(item.itemId)
            self.watchlistMessage = "Added to watchlist"
        }
    }

    func fetchSavedItems() {
        // This should normally be on the main thread since viewContext is main-queue
        let items = coreDataManager.fetchSavedItems()
        DispatchQueue.main.async {
            self.savedItems = items

            let savedIDs = Set(items.compactMap { $0.itemId })
            self.pendingSavedItemIDs.subtract(savedIDs)

            // Rebuild cache from saved items
            for saved in items {
                if let itemAvailability = saved.toCatalogItem().availability,
                   let itemId = saved.itemId {
                    self.availabilityCache[itemId] = itemAvailability
                }
            }
        }
    }

    func removeFromWatchlist(item: CatalogItem) {
        pendingSavedItemIDs.remove(item.itemId)
        coreDataManager.deleteSavedItem(itemId: item.itemId)
        fetchSavedItems()

        DispatchQueue.main.async {
            self.watchlistMessage = "Removed from watchlist"
        }
    }

    func isItemSaved(_ item: CatalogItem) -> Bool {
        pendingSavedItemIDs.contains(item.itemId) ||
        savedItems.contains(where: { $0.itemId == item.itemId })
    }
}
