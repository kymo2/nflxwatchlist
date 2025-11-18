//
//  SavedCatalogItem+Extensions.swift
//  NetflixWatchlist
//
//  Created by Kyle Mooney on 1/31/25.
//

import Foundation


extension SavedCatalogItem {
    func toCatalogItem() -> CatalogItem {
        return CatalogItem(
            itemId: self.itemId ?? "",
            title: self.title ?? "",
            img: self.img ?? "",
            synopsis: self.synopsis ?? "",
            availability: nil
        )
    }
}
