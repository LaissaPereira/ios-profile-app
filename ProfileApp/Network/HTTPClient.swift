//
//  HTTPClient.swift
//  ProfileApp
//
//  Created by Laissa on 21.09.26.
//

import Foundation
// How do I make an HTTP request

protocol HTTPClient {
    func data(from url: URL) async throws -> (Data, URLResponse)
}
