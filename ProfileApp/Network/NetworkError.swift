//
//  NetworkError.swift
//  ProfileApp
//
//  Created by Laissa on 21.09.26.
//

import Foundation

enum NetworkError : Error, Equatable {
    case invalidURL
    case invalidResponse
    case invalidStatusCode(Int)
    case decodingFailed
    case transport
}

enum TestError: Error {
    //Related transport layer because without internet, DNS failure, connection lost and timeout.
    case NetworkFailed
}
