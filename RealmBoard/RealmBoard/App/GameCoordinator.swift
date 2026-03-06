import SwiftUI
import Combine

/// 遊戲階段
enum GamePhase: String, Codable, Equatable {
    case lobby            // 大廳：建立 / 加入房間
    case characterSelect  // 角色建立
    case mapSetup         // 地圖拼接設定
    case adventure        // 冒險探索
    case combat           // 戰鬥回合
}

/// 裝置角色
enum DeviceRole: String, Codable {
    case player           // 玩家手機
    case dungeonMaster    // 城主 (DM) iPad
}

/// 中央遊戲協調器 — 管理所有遊戲狀態
@MainActor
final class GameCoordinator: ObservableObject {
    @Published var phase: GamePhase = .lobby
    @Published var deviceRole: DeviceRole = .player
    @Published var localPlayer: PlayerCharacter?
    @Published var allPlayers: [PlayerCharacter] = []
    @Published var gameState: GameState = GameState()
    @Published var isConnected = false

    let sessionManager = SessionManager()
    let combatEngine = CombatEngine()
    let mapStitcher = MapStitcher()
    let turnManager = TurnManager()

    private var cancellables = Set<AnyCancellable>()

    init() {
        setupBindings()
    }

    private func setupBindings() {
        sessionManager.$connectedPeers
            .map { !$0.isEmpty }
            .assign(to: &$isConnected)

        sessionManager.onMessageReceived = { [weak self] message in
            Task { @MainActor in
                self?.handleMessage(message)
            }
        }
    }

    func hostGame(asRole role: DeviceRole) {
        deviceRole = role
        sessionManager.startHosting()
    }

    func joinGame() {
        deviceRole = .player
        sessionManager.startBrowsing()
    }

    func advancePhase() {
        switch phase {
        case .lobby:
            phase = .characterSelect
        case .characterSelect:
            phase = .mapSetup
        case .mapSetup:
            phase = .adventure
        case .adventure:
            phase = .combat
        case .combat:
            phase = .adventure
        }
        broadcastState()
    }

    func broadcastState() {
        let msg = GameMessage(
            type: .stateSync,
            payload: .stateUpdate(gameState)
        )
        sessionManager.broadcast(msg)
    }

    private func handleMessage(_ message: GameMessage) {
        switch message.type {
        case .stateSync:
            if case .stateUpdate(let state) = message.payload {
                self.gameState = state
            }
        case .diceRoll:
            if case .diceResult(let result) = message.payload {
                combatEngine.applyDiceResult(result)
            }
        case .moveCharacter:
            if case .movement(let move) = message.payload {
                gameState.applyMovement(move)
            }
        case .combatAction:
            if case .combat(let action) = message.payload {
                combatEngine.processAction(action)
            }
        case .chatMessage:
            break
        case .phaseChange:
            if case .phase(let newPhase) = message.payload {
                self.phase = newPhase
            }
        case .mapUpdate:
            if case .mapData(let data) = message.payload {
                mapStitcher.applyRemoteUpdate(data)
            }
        }
    }
}
