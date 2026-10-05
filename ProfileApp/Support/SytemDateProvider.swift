//
//  SytemDateProvider.swift
//  ProfileApp
//
//  Created by Laissa on 29.09.26.
//

import Foundation

struct SytemDateProvider : DateProvider {
    func now() -> Date {
        Date()
    }
}
