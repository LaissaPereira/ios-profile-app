//
//  URLSessionHTTPClient.swift
//  ProfileApp
//
//  Created by Laissa on 21.09.26.
//

import Foundation

struct URLSessionHTTPClient: HTTPClient {
    //Struct HTTPClient can be testable
    func data(from url: URL) async throws -> (Data, URLResponse) {
        try await URLSession.shared.data(from: url)
    }
}
