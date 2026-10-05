//
//  Profile.swift
//  ProfileApp
//
//  Created by Laissa on 18.09.26.
//

import Foundation

//Domain model - data type
struct Profile : Sendable, Codable {
    //Shape/ represent app/domain data
    let name: String
    let city: String
    let skills: [String]
    let followers : Int
}

