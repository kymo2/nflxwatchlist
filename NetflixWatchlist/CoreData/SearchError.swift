//
//  SearchError.swift
//  NetflixWatchlist
//
//  Created by Kyle Mooney on 2/17/25.
//

enum SearchError: Error {
    case invalidURL
    case missingCredentials
    case networkError(String)
    case emptyResults
    case decodingError(String)
}
