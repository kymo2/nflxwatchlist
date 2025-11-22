//
//  SavedCatalogItem+Extensions.swift
//  NetflixWatchlist
//
//  Created by Kyle Mooney on 1/31/25.
//

import Foundation


extension SavedCatalogItem {
    func toCatalogItem() -> CatalogItem {
        let availability = (self.countryAvailability as? Set<SavedCountryAvailability>)?.map { savedCountry in
            CountryAvailability(
                countryCode: savedCountry.countryCode ?? "",
                country: savedCountry.country ?? "",
                audio: savedCountry.audio ?? "",
                subtitle: savedCountry.subtitle ?? ""
            )
        } ?? []

        return CatalogItem(
            itemId: self.itemId ?? "",
            title: self.title ?? "",
            img: self.img ?? "",
            synopsis: self.synopsis ?? "",
            availability: availability.isEmpty ? nil : availability,
            isSavedItem: true
        )
    }
}
