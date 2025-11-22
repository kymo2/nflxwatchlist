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
            
            Text("Remaining API Calls: \(viewModel.remainingApiCalls)")
                .font(.subheadline)
                .fontWeight(.semibold)

            List(viewModel.searchResults, id: \.itemId) { item in
                NavigationLink(destination: CatalogDetailScreen(catalogItem: item, source: .search)) {
                    HStack {
                        AsyncImage(url: URL(string: item.img)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        } placeholder: {
                            Color.gray.opacity(0.2)
                        }
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
