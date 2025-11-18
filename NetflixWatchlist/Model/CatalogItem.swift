//
//  CatalogItem.swift
//  NetflixWatchlist
//
//  Created by Kyle Mooney on 1/30/25.
//

struct CatalogItem: Decodable {
    let itemId: String
    let title: String
    let img: String
    let synopsis: String
    
    var availability: [CountryAvailability]? = nil
}
