//
//  RealProfileService.swift
//  ProfileApp
//
//  Created by Laissa on 21.09.26.
//

import Foundation
//It is responsible for getting a real networking layer: going have transport, status code, decoding and response

struct RealProfileService : ProfileService {
    
    //Inject the networking dependency
    let client: any HTTPClient
    
    
    func fetchProfile() async throws -> Profile {
        guard let url = URL(
            string: "https://example.com/profile"
        )else {
            throw NetworkError.invalidURL
        }
        
        let data: Data
        let response : URLResponse
        do {
            (data, response) = try await client.data(from: url)
        } catch {
            throw NetworkError.transport
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        guard 200..<300 ~=  httpResponse.statusCode else {
            throw NetworkError.invalidStatusCode(
                httpResponse.statusCode
            )
        }
        do {
            let dto = try JSONDecoder().decode(
                ProfileDTO.self, from: data
            )
            return try dto.toDomain()
            
            // return try JSONDecoder().decode(Profile.self, from: data)
        }catch{
            print("Decoding error:", error)
            throw NetworkError.decodingFailed
        }
        
    }
}

