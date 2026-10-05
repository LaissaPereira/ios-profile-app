//
//  DateProvider.swift
//  ProfileApp
//
//  Created by Laissa on 29.09.26.
//

import Foundation

protocol DateProvider : Sendable {
    func now() -> Date
}
