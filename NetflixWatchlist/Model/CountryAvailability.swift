//
//  CountryAvailability.swift
//  NetflixWatchlist
//
//  Created by Kyle Mooney on 1/30/25.
//

struct CountryAvailability: Decodable {
    let countryCode: String
    let country: String
    let audio: String
    let subtitle: String
}
