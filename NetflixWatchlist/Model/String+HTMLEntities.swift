//
//  String+HTMLEntities.swift
//  NetflixWatchlist
//
//  Created by OpenAI Assistant on 2/20/25.
//

import Foundation

extension String {
    func decodedHTMLEntities() -> String {
        guard !isEmpty else { return self }

        let wrappedHTML = "<span>\(self)</span>"
        if let data = wrappedHTML.data(using: .utf8) {
            let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
                .documentType: NSAttributedString.DocumentType.html,
                .characterEncoding: String.Encoding.utf8.rawValue
            ]

            if let attributed = try? NSAttributedString(data: data, options: options, documentAttributes: nil) {
                return attributed.string
            }
        }

        return self
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
    }
}

