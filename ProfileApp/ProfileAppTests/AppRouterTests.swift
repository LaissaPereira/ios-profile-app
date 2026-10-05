//
//  AppRouterTests.swift
//  ProfileAppTests
//
//  Created by Laissa on 27.09.26.
//

import Testing
@testable import ProfileApp
internal import SwiftUI

//Tests the behavior of navigation state changes correctly
@MainActor
struct AppRouterTests {

    @Test("Navigates to a route")
    func navigateAddsrouteToPath() {
        //Arrange
        let router = AppRouter()
        
        //Act
        router.navigate(to: .profile(userID: "user-123"))
        
        //Assert
        #expect(router.path.count == 1)
    }
    
    @Test("Go back removes last route")
    func goBackRemovesRoute() {
        let router = AppRouter()
        
        router.navigate(to: .downloads)
        
        #expect(router.path.count == 1)
        
        router.goBack()
        
        #expect(router.path.isEmpty)
    }
    
    @Test("Go to root clears navigation")
    func goToRootClearsPath(){
        let router = AppRouter()
        
        router.navigate(to: .profile(userID: "user-123"))
        router.navigate(to: .downloads)
        
        #expect(router.path.count == 2)
        
        router.gotToRoot()
        
        #expect(router.path.isEmpty)
    }
    
    @Test("Handles valid profile deeplink")
    func handlesProfileDeeplink(){
        let router = AppRouter()
        
        let url = URL(
            string: "profileapp://profile/user-123"
        )!
        
        router.handle(url)
        
        #expect(router.path.count == 1)
        
    }

}
