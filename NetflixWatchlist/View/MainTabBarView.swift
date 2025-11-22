//
//  MainTabBarView.swift
//  NetflixWatchlist
//
//  Created by Kyle Mooney on 1/31/25.
//

import SwiftUI

struct MainTabBarView: View {
    private enum TabSelection: Hashable {
        case search
        case watchlist
    }

    @State private var selectedTab: TabSelection = .search
    @State private var searchNavigationID = UUID()
    @State private var watchlistNavigationID = UUID()

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationView {
                EntryScreen()
            }
            .id(searchNavigationID)
            .tabItem {
                Label("Search", systemImage: "magnifyingglass")
            }
            .tag(TabSelection.search)

            NavigationView {
                WatchlistScreen()
            }
            .id(watchlistNavigationID)
            .tabItem {
                Label("Watchlist", systemImage: "star.fill")
            }
            .tag(TabSelection.watchlist)
        }
        .onChange(of: selectedTab) { newValue in
            switch newValue {
            case .search:
                searchNavigationID = UUID()
            case .watchlist:
                watchlistNavigationID = UUID()
            }
        }
    }
}
