//
//  MainTabBarView.swift
//  NetflixWatchlist
//
//  Created by Kyle Mooney on 1/31/25.
//

import SwiftUI

struct MainTabBarView: View {
    var body: some View {
        TabView {
            NavigationView {
                EntryScreen()
            }
            .tabItem {
                Label("Search", systemImage: "magnifyingglass")
            }

            NavigationView {
                WatchlistScreen()
            }
            .tabItem {
                Label("Watchlist", systemImage: "star.fill")
            }
        }
    }
}
