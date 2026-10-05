//
//  ProfileDTO.swift
//  ProfileApp
//
//  Created by Laissa on 21.09.26.
//

import Foundation

struct ProfileDTO : Decodable {
    //Shape/ represent external data(API response)
    let name: String
    let city: String
    let skills: [String]
    let followers: String
}
//JSON is messy related properties and typs and DTO layer absorbs the mess and create function for the app stay clean
extension ProfileDTO {
    func toDomain() throws -> Profile {
        guard let followers = Int(followers) else {
            throw NetworkError.decodingFailed
        }
        return Profile(
            name: name,
            city: city,
            skills: skills,
            followers: followers
        )
    }
}
