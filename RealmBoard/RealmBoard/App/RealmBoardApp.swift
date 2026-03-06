import SwiftUI

@main
struct RealmBoardApp: App {
    @StateObject private var gameCoordinator = GameCoordinator()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(gameCoordinator)
        }
    }
}
