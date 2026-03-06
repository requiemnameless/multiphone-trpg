/// 骰子引擎 — 實作 D&D d20 系統，支援各式骰子、優勢/劣勢、屬性檢定與豁免骰
import Foundation

// MARK: - 骰子系統

enum DieType: Codable, Equatable {
    case d4, d6, d8, d10, d12, d20, d100
    case d(Int)  // 自訂面數

    var sides: Int {
        switch self {
        case .d4:  return 4
        case .d6:  return 6
        case .d8:  return 8
        case .d10: return 10
        case .d12: return 12
        case .d20: return 20
        case .d100: return 100
        case .d(let n): return n
        }
    }

    var displayName: String {
        "d\(sides)"
    }
}

struct DiceResult: Codable, Equatable, Identifiable {
    let id: UUID
    let dieType: DieType
    let count: Int
    let rolls: [Int]
    let modifier: Int
    let total: Int
    let isCriticalHit: Bool     // 自然 20
    let isCriticalMiss: Bool    // 自然 1
    let purpose: String         // 擲骰目的（攻擊、豁免、傷害等）

    init(dieType: DieType, count: Int, rolls: [Int], modifier: Int, purpose: String) {
        self.id = UUID()
        self.dieType = dieType
        self.count = count
        self.rolls = rolls
        self.modifier = modifier
        self.total = rolls.reduce(0, +) + modifier
        self.isCriticalHit = dieType == .d20 && count == 1 && rolls.first == 20
        self.isCriticalMiss = dieType == .d20 && count == 1 && rolls.first == 1
        self.purpose = purpose
    }
}

/// 骰子引擎
enum DiceEngine {
    /// 擲單顆骰子
    static func roll(_ die: DieType, modifier: Int = 0, purpose: String = "") -> DiceResult {
        let value = Int.random(in: 1...die.sides)
        return DiceResult(
            dieType: die,
            count: 1,
            rolls: [value],
            modifier: modifier,
            purpose: purpose
        )
    }

    /// 擲多顆骰子
    static func roll(_ count: Int, _ die: DieType, modifier: Int = 0, purpose: String = "") -> DiceResult {
        let rolls = (0..<count).map { _ in Int.random(in: 1...die.sides) }
        return DiceResult(
            dieType: die,
            count: count,
            rolls: rolls,
            modifier: modifier,
            purpose: purpose
        )
    }

    /// 擲 d20 進行屬性檢定
    static func abilityCheck(
        ability: Ability,
        modifier: Int,
        proficiencyBonus: Int = 0,
        advantage: Bool = false,
        disadvantage: Bool = false,
        purpose: String = ""
    ) -> DiceResult {
        let totalMod = modifier + proficiencyBonus

        if advantage && !disadvantage {
            let roll1 = Int.random(in: 1...20)
            let roll2 = Int.random(in: 1...20)
            let best = max(roll1, roll2)
            return DiceResult(
                dieType: .d20, count: 1,
                rolls: [best],
                modifier: totalMod,
                purpose: "\(ability.rawValue)檢定（優勢）\(purpose)"
            )
        } else if disadvantage && !advantage {
            let roll1 = Int.random(in: 1...20)
            let roll2 = Int.random(in: 1...20)
            let worst = min(roll1, roll2)
            return DiceResult(
                dieType: .d20, count: 1,
                rolls: [worst],
                modifier: totalMod,
                purpose: "\(ability.rawValue)檢定（劣勢）\(purpose)"
            )
        } else {
            return roll(.d20, modifier: totalMod, purpose: "\(ability.rawValue)檢定 \(purpose)")
        }
    }

    /// 攻擊擲骰
    static func attackRoll(
        attackBonus: Int,
        advantage: Bool = false,
        disadvantage: Bool = false
    ) -> DiceResult {
        abilityCheck(
            ability: .strength,
            modifier: attackBonus,
            advantage: advantage,
            disadvantage: disadvantage,
            purpose: "攻擊"
        )
    }

    /// 豁免擲骰
    static func savingThrow(
        ability: Ability,
        modifier: Int,
        proficiencyBonus: Int = 0
    ) -> DiceResult {
        roll(.d20, modifier: modifier + proficiencyBonus, purpose: "\(ability.rawValue)豁免")
    }

    /// 先攻擲骰
    static func initiativeRoll(modifier: Int) -> DiceResult {
        roll(.d20, modifier: modifier, purpose: "先攻")
    }

    /// 解析骰子字串 (例如 "2d6+3")
    static func parseDiceString(_ str: String) -> (count: Int, die: DieType, modifier: Int)? {
        let pattern = #"(\d+)d(\d+)([+-]\d+)?"#
        guard let match = str.range(of: pattern, options: .regularExpression) else { return nil }
        let matched = String(str[match])

        let parts = matched.components(separatedBy: "d")
        guard parts.count == 2, let count = Int(parts[0]) else { return nil }

        var diePart = parts[1]
        var modifier = 0

        if let plusRange = diePart.range(of: "+") {
            modifier = Int(diePart[plusRange.upperBound...]) ?? 0
            diePart = String(diePart[..<plusRange.lowerBound])
        } else if let minusRange = diePart.range(of: "-") {
            modifier = -(Int(diePart[minusRange.upperBound...]) ?? 0)
            diePart = String(diePart[..<minusRange.lowerBound])
        }

        guard let sides = Int(diePart) else { return nil }
        return (count, .d(sides), modifier)
    }

    /// 根據骰子字串擲骰
    static func rollFromString(_ str: String, purpose: String = "") -> DiceResult? {
        guard let parsed = parseDiceString(str) else { return nil }
        return roll(parsed.count, parsed.die, modifier: parsed.modifier, purpose: purpose)
    }
}
