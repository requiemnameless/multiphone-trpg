/// 怪物模型 — 定義 D&D 怪物的種類、屬性、攻擊方式與難度分級
import Foundation

// MARK: - 怪物類別

enum MonsterType: String, Codable, CaseIterable {
    case goblin      = "哥布林"
    case skeleton     = "骷髏"
    case orc         = "獸人"
    case zombie      = "殭屍"
    case wolf        = "狼"
    case ogre        = "食人魔"
    case troll       = "巨魔"
    case dragon      = "龍"
    case lich        = "巫妖"
    case mimic       = "擬態怪"
    case beholder    = "眼魔"
    case mindFlayer  = "奪心魔"
}

enum MonsterDifficulty: String, Codable {
    case minion   = "嘍囉"     // CR 0-1
    case standard = "普通"     // CR 2-4
    case elite    = "菁英"     // CR 5-10
    case boss     = "首領"     // CR 11+
}

// MARK: - 怪物

struct Monster: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    var type: MonsterType
    var difficulty: MonsterDifficulty
    var abilities: AbilityScores
    var currentHP: Int
    var maxHP: Int
    var armorClass: Int
    var challengeRating: Double
    var experienceReward: Int
    var attacks: [MonsterAttack]
    var position: GridPosition
    var specialAbilities: [String]

    var isAlive: Bool { currentHP > 0 }
    var initiativeModifier: Int { abilities.modifier(for: .dexterity) }

    mutating func takeDamage(_ amount: Int) {
        currentHP = max(0, currentHP - amount)
    }

    // MARK: - 預設怪物模板

    static func goblin(at position: GridPosition = .zero) -> Monster {
        Monster(
            id: UUID(), name: "哥布林", type: .goblin, difficulty: .minion,
            abilities: AbilityScores(str: 8, dex: 14, con: 10, int: 10, wis: 8, cha: 8),
            currentHP: 7, maxHP: 7, armorClass: 15, challengeRating: 0.25,
            experienceReward: 50,
            attacks: [MonsterAttack(name: "彎刀", toHitBonus: 4, damage: "1d6+2", damageType: .slashing)],
            position: position,
            specialAbilities: ["靈巧脫逃"]
        )
    }

    static func skeleton(at position: GridPosition = .zero) -> Monster {
        Monster(
            id: UUID(), name: "骷髏", type: .skeleton, difficulty: .minion,
            abilities: AbilityScores(str: 10, dex: 14, con: 15, int: 6, wis: 8, cha: 5),
            currentHP: 13, maxHP: 13, armorClass: 13, challengeRating: 0.25,
            experienceReward: 50,
            attacks: [MonsterAttack(name: "短劍", toHitBonus: 4, damage: "1d6+2", damageType: .piercing)],
            position: position,
            specialAbilities: ["黑暗視覺", "易碎（鈍器弱點）"]
        )
    }

    static func orc(at position: GridPosition = .zero) -> Monster {
        Monster(
            id: UUID(), name: "獸人", type: .orc, difficulty: .standard,
            abilities: AbilityScores(str: 16, dex: 12, con: 16, int: 7, wis: 11, cha: 10),
            currentHP: 15, maxHP: 15, armorClass: 13, challengeRating: 0.5,
            experienceReward: 100,
            attacks: [MonsterAttack(name: "巨斧", toHitBonus: 5, damage: "1d12+3", damageType: .slashing)],
            position: position,
            specialAbilities: ["殘暴攻擊"]
        )
    }

    static func dragon(at position: GridPosition = .zero) -> Monster {
        Monster(
            id: UUID(), name: "紅龍", type: .dragon, difficulty: .boss,
            abilities: AbilityScores(str: 27, dex: 10, con: 25, int: 16, wis: 13, cha: 21),
            currentHP: 256, maxHP: 256, armorClass: 19, challengeRating: 17,
            experienceReward: 18000,
            attacks: [
                MonsterAttack(name: "噬咬", toHitBonus: 14, damage: "2d10+8", damageType: .piercing),
                MonsterAttack(name: "爪擊", toHitBonus: 14, damage: "2d6+8", damageType: .slashing),
                MonsterAttack(name: "火焰吐息", toHitBonus: 0, damage: "18d6", damageType: .fire),
            ],
            position: position,
            specialAbilities: ["飛行", "傳奇抗性", "恐懼靈光", "多重攻擊"]
        )
    }
}

// MARK: - 怪物攻擊

struct MonsterAttack: Codable, Equatable {
    let name: String
    let toHitBonus: Int
    let damage: String        // 例如 "2d6+3"
    let damageType: DamageType
}

enum DamageType: String, Codable {
    case slashing  = "揮砍"
    case piercing  = "穿刺"
    case bludgeoning = "鈍擊"
    case fire      = "火焰"
    case cold      = "寒冷"
    case lightning = "閃電"
    case poison    = "毒素"
    case necrotic  = "黯蝕"
    case radiant   = "光輝"
    case psychic   = "心靈"
    case arcane    = "奧術"
}
