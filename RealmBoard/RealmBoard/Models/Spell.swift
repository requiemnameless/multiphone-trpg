/// 法術模型 — 定義法術學派、法術等級、施法效果與預設法術資料庫
import Foundation

// MARK: - 法術系統

enum SpellSchool: String, Codable {
    case abjuration    = "防護"
    case conjuration   = "咒法"
    case divination    = "預言"
    case enchantment   = "附魔"
    case evocation     = "塑能"
    case illusion      = "幻術"
    case necromancy    = "死靈"
    case transmutation = "變化"
}

enum SpellRange: Codable, Equatable {
    case selfOnly
    case touch
    case feet(Int)

    var description: String {
        switch self {
        case .selfOnly:     return "自身"
        case .touch:        return "觸碰"
        case .feet(let ft): return "\(ft) 呎"
        }
    }
}

struct Spell: Codable, Identifiable, Equatable {
    let id: UUID
    let name: String
    let level: Int              // 0 = 戲法 (cantrip)
    let school: SpellSchool
    let castingTime: String
    let range: SpellRange
    let duration: String
    let description: String
    let damage: String?         // nil = 非傷害法術
    let healing: String?        // nil = 非治療法術
    let requiresConcentration: Bool
    let availableFor: [CharacterClass]

    var isCantrip: Bool { level == 0 }

    // MARK: - 預設法術

    static func fireBolt() -> Spell {
        Spell(id: UUID(), name: "火焰箭", level: 0, school: .evocation,
              castingTime: "1 動作", range: .feet(120), duration: "瞬間",
              description: "向目標投射一枚火焰彈。",
              damage: "1d10", healing: nil, requiresConcentration: false,
              availableFor: [.wizard])
    }

    static func magicMissile() -> Spell {
        Spell(id: UUID(), name: "魔法飛彈", level: 1, school: .evocation,
              castingTime: "1 動作", range: .feet(120), duration: "瞬間",
              description: "射出三枚必中的魔法飛彈，每枚造成 1d4+1 力場傷害。",
              damage: "3d4+3", healing: nil, requiresConcentration: false,
              availableFor: [.wizard])
    }

    static func cureWounds() -> Spell {
        Spell(id: UUID(), name: "治療創傷", level: 1, school: .evocation,
              castingTime: "1 動作", range: .touch, duration: "瞬間",
              description: "觸碰一個生物，恢復其 1d8 + 施法屬性調整值的 HP。",
              damage: nil, healing: "1d8", requiresConcentration: false,
              availableFor: [.cleric, .bard, .ranger])
    }

    static func shield() -> Spell {
        Spell(id: UUID(), name: "護盾術", level: 1, school: .abjuration,
              castingTime: "1 反應", range: .selfOnly, duration: "1 輪",
              description: "以反應動作施放，AC +5 直到下回合開始。",
              damage: nil, healing: nil, requiresConcentration: false,
              availableFor: [.wizard])
    }

    static func fireball() -> Spell {
        Spell(id: UUID(), name: "火球術", level: 3, school: .evocation,
              castingTime: "1 動作", range: .feet(150), duration: "瞬間",
              description: "一顆火球在指定位置爆炸，20呎半徑內所有生物需進行敏捷豁免。",
              damage: "8d6", healing: nil, requiresConcentration: false,
              availableFor: [.wizard])
    }

    static func bless() -> Spell {
        Spell(id: UUID(), name: "祝福術", level: 1, school: .enchantment,
              castingTime: "1 動作", range: .feet(30), duration: "專注，最長 1 分鐘",
              description: "最多三名友方在攻擊骰和豁免骰上額外 +1d4。",
              damage: nil, healing: nil, requiresConcentration: true,
              availableFor: [.cleric])
    }

    static func sneakAttack() -> Spell {
        Spell(id: UUID(), name: "偷襲", level: 0, school: .transmutation,
              castingTime: "無（攻擊附加）", range: .selfOnly, duration: "瞬間",
              description: "當你擁有優勢或盟友在目標 5 呎內時，額外造成偷襲傷害。",
              damage: "1d6", healing: nil, requiresConcentration: false,
              availableFor: [.rogue])
    }
}
