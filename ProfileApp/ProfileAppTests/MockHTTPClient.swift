//
//  MockHTTPClient.swift
//  ProfileApp
//
//  Created by Laissa on 21.09.26.
//

import Foundation
@testable import ProfileApp

//networking test
struct MockHTTPClient: HTTPClient {
    
    let result: Result<(Data, URLResponse), Error>
    
    func data(from url: URL) async throws -> (Data, URLResponse){
        try result.get()
    }
}
