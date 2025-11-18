//
//  SearchResultsScreen.swift
//  NetflixWatchlist
//
//  Created by Kyle Mooney on 1/31/25.
//

import SwiftUI

struct SearchResultsScreen: View {
    @EnvironmentObject var viewModel: SearchViewModel

    var body: some View {
        VStack {
            
            Text("\(viewModel.apiCallCount)")
                .font(.title)
                .fontWeight(.bold)

            List(viewModel.searchResults, id: \.itemId) { item in
                NavigationLink(destination: CatalogDetailScreen(catalogItem: item)) {
                    HStack {
                        AsyncImage(url: URL(string: item.img))
                            .frame(width: 50, height: 75)
                            .cornerRadius(8)
                        
                        VStack(alignment: .leading) {
                            Text(item.title)
                                .font(.headline)
                            Text(item.synopsis)
                                .font(.subheadline)
                                .lineLimit(2)
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
        }
        .navigationTitle("Search Results")
    }
}
