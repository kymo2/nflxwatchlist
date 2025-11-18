//
//  NetflixWatchlistApp.swift
//  NetflixWatchlist
//
//  Created by Kyle Mooney on 1/30/25.
//

import SwiftUI

@main
struct NetflixWatchlistApp: App {
    var body: some Scene {
        WindowGroup {
            MainTabBarView()
                .environmentObject(SearchViewModel())
                .environmentObject(WatchlistViewModel())
        }
    }
}
