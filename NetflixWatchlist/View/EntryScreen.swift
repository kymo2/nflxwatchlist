//
//  EntryScreen.swift
//  NetflixWatchlist
//
//  Created by Kyle Mooney on 1/30/25.
//
import SwiftUI

struct EntryScreen: View {
    @State private var searchQuery = ""
    @State private var isShowingResults = false
    @EnvironmentObject var viewModel: SearchViewModel

    var body: some View {
        VStack {
            Spacer()
            
            Text("\(viewModel.apiCallCount)")
                .font(.title)
                .fontWeight(.bold)

            
            Image(systemName: "film") // Placeholder for logo
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .padding()
            
            Text("Netflix Watchlist")
                .font(.largeTitle)
                .fontWeight(.bold)

            Spacer()
            
            TextField("Search for a Movie or TV Show", text: $searchQuery, onCommit: {
                let trimmedQuery = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmedQuery.isEmpty else { return }

                isShowingResults = true
                viewModel.searchCatalog(title: trimmedQuery)
            })
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .padding()

            NavigationLink(
                destination: SearchResultsScreen(),
                isActive: $isShowingResults
            ) {
                EmptyView()
            }
            
//            NavigationLink {
//                SearchResultsScreen()
//            } label: {
//                !viewModel.searchResults.isEmpty ? Text("View Search Results") : Text("No Results Found")
//            }

            
            
            Spacer()
        }
        .padding()
    }
}
