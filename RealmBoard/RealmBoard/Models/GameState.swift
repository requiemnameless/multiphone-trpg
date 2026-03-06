/// 遊戲狀態 — 統一管理地圖、角色、怪物、回合等全域可同步狀態
import Foundation

// MARK: - 遊戲狀態

struct GameState: Codable, Equatable {
    var map: GameMap
    var players: [PlayerCharacter]
    var monsters: [Monster]
    var currentTurn: Int
    var turnOrder: [CombatantRef]
    var activePlayerIndex: Int
    var isInCombat: Bool
    var roundNumber: Int
    var eventLog: [GameEvent]

    init() {
        self.map = GameMap.sampleDungeon()
        self.players = []
        self.monsters = []
        self.currentTurn = 0
        self.turnOrder = []
        self.activePlayerIndex = 0
        self.isInCombat = false
        self.roundNumber = 0
        self.eventLog = []
    }

    mutating func applyMovement(_ move: MovementData) {
        if let idx = players.firstIndex(where: { $0.id == move.characterId }) {
            // 清除舊位置
            let oldPos = players[idx].position
            if var tile = map.tile(at: oldPos) {
                tile.occupant = nil
                map.setTile(tile, at: oldPos)
            }
            // 設定新位置
            players[idx].position = move.destination
            if var tile = map.tile(at: move.destination) {
                tile.occupant = .player(move.characterId)
                map.setTile(tile, at: move.destination)
            }
        }
    }

    mutating func addEvent(_ event: GameEvent) {
        eventLog.append(event)
        if eventLog.count > 100 {
            eventLog.removeFirst()
        }
    }
}

// MARK: - 戰鬥者引用

enum CombatantRef: Codable, Equatable {
    case player(UUID)
    case monster(UUID)
}

// MARK: - 移動資料

struct MovementData: Codable, Equatable {
    let characterId: UUID
    let destination: GridPosition
    let path: [GridPosition]
}

// MARK: - 遊戲事件

struct GameEvent: Codable, Equatable, Identifiable {
    let id: UUID
    let timestamp: Date
    let type: GameEventType
    let description: String

    init(type: GameEventType, description: String) {
        self.id = UUID()
        self.timestamp = Date()
        self.type = type
        self.description = description
    }
}

enum GameEventType: String, Codable {
    case combat     = "戰鬥"
    case movement   = "移動"
    case dialogue   = "對話"
    case loot       = "拾取"
    case levelUp    = "升級"
    case death      = "死亡"
    case trap       = "陷阱"
    case spell      = "法術"
    case rest       = "休息"
    case system     = "系統"
}
