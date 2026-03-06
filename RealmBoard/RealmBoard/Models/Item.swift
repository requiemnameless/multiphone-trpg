import Foundation

// MARK: - 物品系統

enum ItemRarity: String, Codable {
    case common    = "普通"
    case uncommon  = "非凡"
    case rare      = "稀有"
    case veryRare  = "極稀有"
    case legendary = "傳說"
}

struct Item: Codable, Identifiable, Equatable {
    let id: UUID
    let name: String
    let description: String
    let rarity: ItemRarity
    let weight: Double
    let value: Int   // 金幣價值

    static func healthPotion() -> Item {
        Item(id: UUID(), name: "治療藥水", description: "恢復 2d4+2 HP",
             rarity: .common, weight: 0.5, value: 50)
    }

    static func torch() -> Item {
        Item(id: UUID(), name: "火把", description: "照亮 20 呎半徑，持續 1 小時",
             rarity: .common, weight: 1, value: 1)
    }

    static func rope() -> Item {
        Item(id: UUID(), name: "繩索 (50呎)", description: "麻繩，可用於攀爬或綑綁",
             rarity: .common, weight: 10, value: 1)
    }
}

// MARK: - 武器

enum WeaponCategory: String, Codable {
    case simple  = "簡易武器"
    case martial = "軍用武器"
}

struct Weapon: Codable, Identifiable, Equatable {
    let id: UUID
    let name: String
    let category: WeaponCategory
    let damage: String          // 例如 "1d8"
    let damageType: DamageType
    let range: Int?             // nil = 近戰
    let properties: [String]
    let rarity: ItemRarity
    let value: Int

    var isMelee: Bool { range == nil }
    var isRanged: Bool { range != nil }

    // 預設武器
    static func longsword() -> Weapon {
        Weapon(id: UUID(), name: "長劍", category: .martial,
               damage: "1d8", damageType: .slashing, range: nil,
               properties: ["靈巧"], rarity: .common, value: 15)
    }

    static func shortbow() -> Weapon {
        Weapon(id: UUID(), name: "短弓", category: .simple,
               damage: "1d6", damageType: .piercing, range: 80,
               properties: ["雙手", "彈藥"], rarity: .common, value: 25)
    }

    static func dagger() -> Weapon {
        Weapon(id: UUID(), name: "匕首", category: .simple,
               damage: "1d4", damageType: .piercing, range: 20,
               properties: ["靈巧", "輕型", "投擲"], rarity: .common, value: 2)
    }

    static func staff() -> Weapon {
        Weapon(id: UUID(), name: "法杖", category: .simple,
               damage: "1d6", damageType: .bludgeoning, range: nil,
               properties: ["靈巧"], rarity: .common, value: 5)
    }

    static func greataxe() -> Weapon {
        Weapon(id: UUID(), name: "巨斧", category: .martial,
               damage: "1d12", damageType: .slashing, range: nil,
               properties: ["重型", "雙手"], rarity: .common, value: 30)
    }

    static func flameTongue() -> Weapon {
        Weapon(id: UUID(), name: "焰舌劍", category: .martial,
               damage: "1d8+2d6", damageType: .fire, range: nil,
               properties: ["靈巧", "火焰附魔"], rarity: .rare, value: 5000)
    }
}

// MARK: - 護甲

enum ArmorType: String, Codable {
    case light  = "輕甲"
    case medium = "中甲"
    case heavy  = "重甲"
    case shield = "盾牌"
}

struct Armor: Codable, Identifiable, Equatable {
    let id: UUID
    let name: String
    let type: ArmorType
    let baseAC: Int
    let maxDexBonus: Int?   // nil = 無上限 (輕甲)
    let strengthRequired: Int
    let stealthDisadvantage: Bool
    let rarity: ItemRarity
    let value: Int

    static func leather() -> Armor {
        Armor(id: UUID(), name: "皮甲", type: .light,
              baseAC: 11, maxDexBonus: nil, strengthRequired: 0,
              stealthDisadvantage: false, rarity: .common, value: 10)
    }

    static func chainMail() -> Armor {
        Armor(id: UUID(), name: "鏈甲", type: .heavy,
              baseAC: 16, maxDexBonus: 0, strengthRequired: 13,
              stealthDisadvantage: true, rarity: .common, value: 75)
    }

    static func shield() -> Armor {
        Armor(id: UUID(), name: "盾牌", type: .shield,
              baseAC: 2, maxDexBonus: nil, strengthRequired: 0,
              stealthDisadvantage: false, rarity: .common, value: 10)
    }
}
