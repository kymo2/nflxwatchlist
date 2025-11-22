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
    @Published var pendingSavedItemIDs: Set<String> = []

    private var availabilityCache: [String: [CountryAvailability]] = [:]

    private let service = UnogsService()
    private let coreDataManager = CoreDataManager.shared

    init() {
        fetchSavedItems()
        remainingApiCalls = service.remainingApiCalls()
    }

    func searchCatalog(title: String) {
        DispatchQueue.main.async {
            self.searchResults = []
        }

        service.searchCatalogItems(title: title) { result in
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
                        self.errorMessage = "No results found for \"\(title)\"."
                    case .decodingError(let message):
                        self.errorMessage = "Failed to process data: \(message)"
                    }
//                    self.searchResults = []
                }
            }
        }
        remainingApiCalls = service.remainingApiCalls()
    }

    func fetchAvailability(for catalogItem: CatalogItem) {
        if let cachedAvailability = availabilityCache[catalogItem.itemId], !cachedAvailability.isEmpty {
            DispatchQueue.main.async {
                self.selectedAvailability = cachedAvailability
            }
            return
        }

        if let embeddedAvailability = catalogItem.availability, !embeddedAvailability.isEmpty {
            availabilityCache[catalogItem.itemId] = embeddedAvailability

            DispatchQueue.main.async {
                self.selectedAvailability = embeddedAvailability
            }
            return
        }

        // Do not trigger a network request or consume API counts for watchlist items
        if catalogItem.isSavedItem {
            DispatchQueue.main.async {
                self.selectedAvailability = []
            }
            return
        }

        service.fetchCatalogItemAvailability(itemId: catalogItem.itemId, countTowardsUsage: true) { [weak self] availability in
            guard let self = self else { return }

            self.availabilityCache[catalogItem.itemId] = availability

            DispatchQueue.main.async {
                self.selectedAvailability = availability
                self.remainingApiCalls = self.service.remainingApiCalls()
                self.updateSearchResultAvailability(itemId: catalogItem.itemId, availability: availability)
            }
        }
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



    func fetchSavedItems() {
        savedItems = coreDataManager.fetchSavedItems()
        let savedIDs = Set(savedItems.compactMap { $0.itemId })
        pendingSavedItemIDs.subtract(savedIDs)

        for saved in savedItems {
            if let itemAvailability = saved.toCatalogItem().availability {
                availabilityCache[saved.itemId ?? ""] = itemAvailability
            }
        }

//        // ✅ Print to console for debugging
//        print("🎥 Saved Movies in Core Data:")
        for item in savedItems {
            print("🎬 Title: \(item.title ?? "Unknown") | Netflix ID: \(item.itemId ?? "N/A")")
            if let countrySet = item.countryAvailability as? Set<SavedCountryAvailability> {
                for country in countrySet {
                    print("🌍 Available in: \(country.country ?? "Unknown") (\(country.countryCode ?? ""))")
                }
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
