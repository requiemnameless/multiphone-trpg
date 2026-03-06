import SwiftUI

/// 主要入口畫面 — 根據遊戲狀態切換不同介面
struct ContentView: View {
    @EnvironmentObject var coordinator: GameCoordinator

    var body: some View {
        Group {
            switch coordinator.phase {
            case .lobby:
                LobbyView()
            case .characterSelect:
                CharacterCreationView()
            case .mapSetup:
                MapSetupView()
            case .adventure:
                AdventureView()
            case .combat:
                CombatView()
            }
        }
        .animation(.easeInOut, value: coordinator.phase)
    }
}
