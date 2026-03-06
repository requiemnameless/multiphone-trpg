/// 網路訊息模型 — 定義多裝置之間傳遞的所有訊息類型與資料結構
import Foundation

// MARK: - 網路訊息

struct GameMessage: Codable {
    let id: UUID
    let type: MessageType
    let payload: MessagePayload
    let senderID: String
    let timestamp: Date

    init(type: MessageType, payload: MessagePayload, senderID: String = "") {
        self.id = UUID()
        self.type = type
        self.payload = payload
        self.senderID = senderID
        self.timestamp = Date()
    }
}

enum MessageType: String, Codable {
    case stateSync       // 全局狀態同步
    case diceRoll        // 骰子結果
    case moveCharacter   // 角色移動
    case combatAction    // 戰鬥行動
    case chatMessage     // 聊天訊息
    case phaseChange     // 遊戲階段變更
    case mapUpdate       // 地圖更新
}

enum MessagePayload: Codable, Equatable {
    case stateUpdate(GameState)
    case diceResult(DiceResult)
    case movement(MovementData)
    case combat(CombatAction)
    case chat(ChatData)
    case phase(GamePhase)
    case mapData(MapUpdateData)
}

// MARK: - 戰鬥行動

struct CombatAction: Codable, Equatable {
    let actorId: UUID
    let type: CombatActionType
    let targetId: UUID?
    let spellId: UUID?
    let itemId: UUID?
}

enum CombatActionType: String, Codable {
    case attack     = "攻擊"
    case castSpell  = "施法"
    case useItem    = "使用物品"
    case dodge      = "迴避"
    case dash       = "衝刺"
    case disengage  = "脫離"
    case hide       = "躲藏"
    case help       = "幫助"
    case endTurn    = "結束回合"
}

// MARK: - 聊天資料

struct ChatData: Codable, Equatable {
    let senderName: String
    let message: String
    let isNarration: Bool   // DM 敘事
}

// MARK: - 地圖更新資料

struct MapUpdateData: Codable, Equatable {
    let updatedTiles: [MapTile]
    let newMonsters: [Monster]
    let removedMonsterIds: [UUID]
    let fogReveal: [GridPosition]
}
