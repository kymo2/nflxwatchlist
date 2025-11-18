//
//  Untitled.swift
//  NetflixWatchlist
//
//  Created by Kyle Mooney on 1/31/25.
//

import CoreData
import SwiftUI

// https://developer.apple.com/documentation/coredata/setting_up_a_core_data_stack

class CoreDataManager: ObservableObject {
    static let shared = CoreDataManager()
    
    lazy var persistentContainer: NSPersistentContainer = {
        
        let container = NSPersistentContainer(name: "NetflixWatchlist")
        
        container.loadPersistentStores { _, error in
            if let error = error {
                print("Error loading Core Data: \(error.localizedDescription)")
            }
        }
        return container
    }()
    
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    private init() {}
    
    func fetchSavedItems() -> [SavedCatalogItem] {
        let fetchRequest: NSFetchRequest<SavedCatalogItem> = SavedCatalogItem.fetchRequest()
        
        fetchRequest.relationshipKeyPathsForPrefetching = ["countryAvailability"]

        do {
            let items = try self.context.fetch(fetchRequest)

            print("🎥 Saved Movies in Core Data:")
            for item in items {
                print("Title: \(item.title ?? "Unknown") | Netflix ID: \(item.itemId ?? "N/A")")
                print("Img URL: \(item.img ?? "No Image")")

                if let countrySet = item.countryAvailability as? Set<SavedCountryAvailability>, !countrySet.isEmpty {
                    print("Available in:")
                    for country in countrySet {
                        print("  - \(country.country ?? "Unknown") (\(country.countryCode ?? "")) | Audio: \(country.audio ?? "N/A")")
                    }
                } else {
                    print("No country availability data found.")
                }
            }

            return items
        } catch {
            print("Error fetching saved items: \(error.localizedDescription)")
            return []
        }
    }
        
    func saveCatalogItem(item: CatalogItem, availability: [CountryAvailability]) {
        if self.itemExists(itemId: item.itemId, in: context) {
            return
        }
        
        context.perform {
            let savedItem = SavedCatalogItem(context: self.context)

            savedItem.itemId = item.itemId
            savedItem.title = item.title
            savedItem.synopsis = item.synopsis
            savedItem.img = item.img
    
            let countrySet = NSMutableSet()

            for country in availability {
                let savedCountry = SavedCountryAvailability(context: self.context)
                
                savedCountry.countryCode = country.countryCode
                savedCountry.country = country.country
                savedCountry.audio = country.audio
                savedCountry.subtitle = country.subtitle
                
                savedCountry.savedCatalogItem = savedItem
                countrySet.add(savedCountry)
            }

            savedItem.countryAvailability = countrySet

            do {
                try self.context.save()
                print("Successfully saved \(item.title) with \(availability.count) countries")
            } catch {
                print("Error saving Core Data: \(error.localizedDescription)")
            }
        }
    }
    
}

extension CoreDataManager {
    
    func saveContext() {
        guard context.hasChanges else { return }
        
        do {
            try context.save()
        } catch {
            print("Failed to save the context: ", error.localizedDescription)
        }
    }
    
    func deleteSavedItem(item: SavedCatalogItem) {
        context.delete(item)
        saveContext()
    }

    func deleteSavedItem(itemId: String) {
        let fetchRequest: NSFetchRequest<SavedCatalogItem> = SavedCatalogItem.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "itemId == %@", itemId)
        fetchRequest.fetchLimit = 1

        do {
            if let item = try context.fetch(fetchRequest).first {
                deleteSavedItem(item: item)
            }
        } catch {
            print("Failed to delete item with id \(itemId): \(error.localizedDescription)")
        }
    }
    
    func itemExists(itemId: String, in context: NSManagedObjectContext) -> Bool {
        let fetchRequest: NSFetchRequest<SavedCatalogItem> = SavedCatalogItem.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "itemId == %@", itemId)
        fetchRequest.fetchLimit = 1
        
        do {
            let count = try context.count(for: fetchRequest)
            return count > 0
        } catch {
            return false
        }

    }
}
    
