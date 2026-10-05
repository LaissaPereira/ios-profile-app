//
//  ProfileUpdate.swift
//  ProfileApp
//
//  Created by Laissa on 29.09.26.
//

import Foundation

enum ProfileUpdate : Sendable {
    case cached(Profile)
    case fresh(Profile)
}
