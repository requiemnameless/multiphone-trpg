/// RealmBoard App 入口 — 初始化遊戲協調器並啟動主畫面
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
