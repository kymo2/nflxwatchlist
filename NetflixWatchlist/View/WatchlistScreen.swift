//
//  WatchlistScreen.swift
//  NetflixWatchlist
//
//  Created by Kyle Mooney on 1/31/25.
//

import SwiftUI

struct WatchlistScreen: View {
    @EnvironmentObject var watchlistViewModel: WatchlistViewModel

    var body: some View {
        VStack {
            List {
                ForEach(watchlistViewModel.savedItems, id: \.objectID) { item in
                    NavigationLink(destination: CatalogDetailScreen(catalogItem: item.toCatalogItem())) {
                        HStack {
                            AsyncImage(url: URL(string: item.img ?? ""))
                                .frame(width: 50, height: 75)
                                .cornerRadius(8)

                            VStack(alignment: .leading) {
                                Text(item.title ?? "Unknown Title")
                                    .font(.headline)
                            }
                        }
                    }
                }
                .onDelete { indexSet in
                    indexSet.forEach { index in
                        let item = watchlistViewModel.savedItems[index]
                        watchlistViewModel.removeFromWatchlist(item)
                    }
                }
            }
        }
        .navigationTitle("Watchlist")
        .onAppear {
            watchlistViewModel.fetchSavedItems()
        }
    }
}
