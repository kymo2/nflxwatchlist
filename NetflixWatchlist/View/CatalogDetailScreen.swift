//
//  CatalogDetailScreen.swift
//  NetflixWatchlist
//
//  Created by Kyle Mooney on 1/31/25.
//

import SwiftUI

struct CatalogDetailScreen: View {
    let catalogItem: CatalogItem
    @EnvironmentObject var viewModel: SearchViewModel

    var body: some View {
        VStack {
            Text("Remaining API Calls: \(viewModel.remainingApiCalls)")
                .font(.title3)
                .fontWeight(.semibold)

            AsyncImage(url: URL(string: catalogItem.img)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } placeholder: {
                Color.gray.opacity(0.2)
            }
            .frame(width: 150, height: 225)
            .cornerRadius(8)
            
            Text(catalogItem.title)
                .font(.title)
                .fontWeight(.bold)

            Text(catalogItem.synopsis)
                .font(.subheadline)
                .padding()

            Button(action: {
                if viewModel.isItemSaved(catalogItem) {
                    viewModel.removeFromWatchlist(item: catalogItem)
                } else {
                    viewModel.saveToWatchlist(item: catalogItem)
                }
            }) {
                Text(viewModel.isItemSaved(catalogItem) ? "Remove from Watchlist" : "Add to Watchlist")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(viewModel.isItemSaved(catalogItem) ? Color.red : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding()

            List(viewModel.selectedAvailability, id: \ .countryCode) { country in
                HStack {
                    Text("\(country.country) (\(country.countryCode))")
                    Spacer()
                    Text("🎬 Audio: \(country.audio)")
                }
            }
        }
        .navigationTitle("Title Details")
        .onAppear {
            viewModel.fetchSavedItems()
        }
    }
}
