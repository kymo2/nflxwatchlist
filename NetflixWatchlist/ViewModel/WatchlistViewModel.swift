//
//  WatchlistViewModel.swift
//  NetflixWatchlist
//
//  Created by Kyle Mooney on 1/31/25.
//

import Foundation
import CoreData

class WatchlistViewModel: ObservableObject {
    @Published var savedItems: [SavedCatalogItem] = []

    private let coreDataManager = CoreDataManager.shared

    init() {
        fetchSavedItems() // Load saved items when the app starts
    }

    func fetchSavedItems() {
        savedItems = coreDataManager.fetchSavedItems()

        // ✅ Debugging: Print saved watchlist items
        print("🎥 Saved Movies in Core Data:")
        for item in savedItems {
            print("🎬 Title: \(item.title ?? "Unknown") | 📌 Netflix ID: \(item.itemId ?? "N/A")")
        }
    }

    func removeFromWatchlist(_ item: SavedCatalogItem) {
        coreDataManager.deleteSavedItem(item: item)
        fetchSavedItems() // Refresh after deletion
    }

    func clearWatchlist() {
        coreDataManager.deleteAllSavedItems()
        fetchSavedItems()
    }
}
