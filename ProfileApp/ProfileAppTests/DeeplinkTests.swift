//
//  DeeplinkTests.swift
//  ProfileAppTests
//
//  Created by Laissa on 26.09.26.
//

import Testing
import Foundation
@testable import ProfileApp
@MainActor
struct DeeplinkTests {
    //Testing deep link parser is now proven by tests

    @Test("Parse valid profile deep link")
    func parsesProfileDeeplink() async throws {
        //Arrange
        let url = URL(
            string: "profileapp://profile/user-123"
        )!
        //Act
        let deeplink = DeepLink(url: url)
        
        //Assert
        #expect(
            deeplink == .profile(userID: "user-123")
        )
        
    }
    
    @Test("Rejects wrong URL scheme")
    func rejectsWrongScheme() {
        let url = URL(
            string: "wrongapp://profile/user-123"
        )!
        let deeplink = DeepLink(url: url)
        
        #expect(deeplink == nil)
    }
    
    @Test("Rejects unssupported deep link")
    func rejectsUnkownHost() {
        let url = URL(
            string: "profileapp://settings/test"
        )!
        let deeplink = DeepLink(url: url)
        
        #expect(deeplink == nil)
    }

}
