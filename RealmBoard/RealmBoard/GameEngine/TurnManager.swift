import Foundation
import Combine

/// 回合管理器 — 管理探索模式與戰鬥模式的回合流程
@MainActor
final class TurnManager: ObservableObject {
    @Published var currentPhase: TurnPhase = .exploration
    @Published var activePlayerId: UUID?
    @Published var movementRemaining: Int = 0
    @Published var hasUsedAction: Bool = false
    @Published var hasUsedBonusAction: Bool = false
    @Published var hasUsedReaction: Bool = false

    enum TurnPhase: String {
        case exploration   = "探索"
        case combat        = "戰鬥"
        case shopping      = "商店"
        case dialogue      = "對話"
        case rest          = "休息"
    }

    /// 開始一位玩家的回合
    func beginTurn(for player: PlayerCharacter) {
        activePlayerId = player.id
        movementRemaining = player.race.speed / 5  // 每 5 呎 = 1 格
        hasUsedAction = false
        hasUsedBonusAction = false
        hasUsedReaction = false
    }

    /// 移動消耗
    func consumeMovement(_ tiles: Int, terrain: TerrainType) -> Bool {
        let cost = tiles * terrain.movementCost
        guard movementRemaining >= cost else { return false }
        movementRemaining -= cost
        return true
    }

    /// 使用動作
    func useAction() -> Bool {
        guard !hasUsedAction else { return false }
        hasUsedAction = true
        return true
    }

    /// 使用附贈動作
    func useBonusAction() -> Bool {
        guard !hasUsedBonusAction else { return false }
        hasUsedBonusAction = true
        return true
    }

    /// 結束回合
    func endTurn() {
        activePlayerId = nil
        movementRemaining = 0
        hasUsedAction = false
        hasUsedBonusAction = false
        hasUsedReaction = false
    }

    /// 短休息 — 消耗生命骰恢復 HP
    func shortRest(player: inout PlayerCharacter) {
        let healRoll = DiceEngine.roll(.d(player.characterClass.hitDie),
                                        modifier: player.abilities.modifier(for: .constitution),
                                        purpose: "短休息回復")
        player.heal(healRoll.total)
    }

    /// 長休息 — 完全回復
    func longRest(player: inout PlayerCharacter) {
        player.currentHP = player.maxHP
    }
}
