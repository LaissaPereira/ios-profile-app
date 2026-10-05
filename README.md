# iOS Profile App 📱

A native iOS application built with **Swift and SwiftUI** as part of my journey toward becoming an iOS Developer.

The project focuses on modern iOS development practices including clean architecture, Swift Concurrency, networking, caching, dependency injection, navigation, and testing.

## 🛠 Technologies

- Swift
- SwiftUI
- Xcode
- Swift Concurrency
- async/await
- AsyncSequence
- AsyncThrowingStream
- URLSession
- Observation (`@Observable`, `@Bindable`)
- NavigationStack

## 🏗 Architecture

The project separates responsibilities using protocols and dependency injection.

Main components include:

- `ProfileService` — retrieves profile data
- `ProfileCache` — manages cached profile data
- `ProfileRepository` — coordinates remote and cached data
- `DefaultProfileRepository` — repository implementation
- `ProfileModel` — manages UI state
- `ProfileView` — presents loading, error, and profile states

The architecture is designed to keep the application modular, testable, and maintainable.

## ⚡ Concurrency

The project explores modern Swift concurrency concepts including:

- `async/await`
- `AsyncSequence`
- `AsyncThrowingStream`
- asynchronous networking
- request coordination
- concurrency-safe state management

## 💾 Caching

Profile data can be cached locally and reused while it remains valid.

The repository determines whether cached data is fresh or whether new data should be requested from the remote service.

## 🧭 Navigation

The application uses `NavigationStack` and supports deep links such as:

`profileapp://profile/<user-id>`

## 🧪 Testing

The project includes tests using mock implementations of services and repositories to validate application behavior without relying on real network requests.

## 🚧 Status

This project is currently under active development while I continue learning and implementing production-style iOS engineering concepts.
