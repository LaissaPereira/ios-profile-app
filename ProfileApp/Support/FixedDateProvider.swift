//
//  FixedDateProvider.swift
//  ProfileApp
//
//  Created by Laissa on 29.09.26.
//

import Foundation

struct FixedDateProvider : DateProvider {
    let date : Date
    
    func now() -> Date {
        date
    }
}
