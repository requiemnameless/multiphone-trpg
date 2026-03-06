import Foundation

// MARK: - 種族 (Race)

enum Race: String, Codable, CaseIterable, Identifiable {
    case human    = "人類"
    case elf      = "精靈"
    case dwarf    = "矮人"
    case halfling = "半身人"
    case dragonborn = "龍裔"
    case tiefling = "提夫林"

    var id: String { rawValue }

    /// 種族屬性加成
    var abilityBonuses: AbilityScores {
        switch self {
        case .human:      return AbilityScores(str: 1, dex: 1, con: 1, int: 1, wis: 1, cha: 1)
        case .elf:        return AbilityScores(str: 0, dex: 2, con: 0, int: 1, wis: 0, cha: 0)
        case .dwarf:      return AbilityScores(str: 0, dex: 0, con: 2, int: 0, wis: 1, cha: 0)
        case .halfling:   return AbilityScores(str: 0, dex: 2, con: 0, int: 0, wis: 0, cha: 1)
        case .dragonborn: return AbilityScores(str: 2, dex: 0, con: 0, int: 0, wis: 0, cha: 1)
        case .tiefling:   return AbilityScores(str: 0, dex: 0, con: 0, int: 1, wis: 0, cha: 2)
        }
    }

    var description: String {
        switch self {
        case .human:      return "適應力強的萬能種族，在各方面都有均衡成長。"
        case .elf:        return "優雅的長壽種族，擅長魔法與弓箭。"
        case .dwarf:      return "堅韌的山岳種族，精通鍛造與戰鬥。"
        case .halfling:   return "小巧敏捷的種族，擁有驚人的好運。"
        case .dragonborn: return "擁有龍之血統的強大戰士，能噴吐龍息。"
        case .tiefling:   return "具有惡魔血統的神祕種族，天生掌握暗黑魔法。"
        }
    }

    var speed: Int {
        switch self {
        case .human, .elf, .dragonborn, .tiefling: return 30
        case .dwarf, .halfling: return 25
        }
    }
}

// MARK: - 職業 (Class)

enum CharacterClass: String, Codable, CaseIterable, Identifiable {
    case fighter  = "戰士"
    case wizard   = "法師"
    case rogue    = "盜賊"
    case cleric   = "牧師"
    case ranger   = "遊俠"
    case bard     = "吟遊詩人"

    var id: String { rawValue }

    var hitDie: Int {
        switch self {
        case .fighter:  return 10
        case .wizard:   return 6
        case .rogue:    return 8
        case .cleric:   return 8
        case .ranger:   return 10
        case .bard:     return 8
        }
    }

    var primaryAbility: Ability {
        switch self {
        case .fighter:  return .strength
        case .wizard:   return .intelligence
        case .rogue:    return .dexterity
        case .cleric:   return .wisdom
        case .ranger:   return .dexterity
        case .bard:     return .charisma
        }
    }

    var description: String {
        switch self {
        case .fighter:  return "精通各種武器與護甲的近戰大師。"
        case .wizard:   return "鑽研奧術的魔法使用者，能施放強大法術。"
        case .rogue:    return "擅長潛行與偷襲的暗影刺客。"
        case .cleric:   return "信仰神明的治療者，能驅散不死生物。"
        case .ranger:   return "精通弓術與追蹤的荒野獵人。"
        case .bard:     return "以歌聲施展魔法的旅行藝人。"
        }
    }

    var startingSkills: [Skill] {
        switch self {
        case .fighter:  return [.athletics, .intimidation]
        case .wizard:   return [.arcana, .investigation]
        case .rogue:    return [.stealth, .sleightOfHand, .acrobatics]
        case .cleric:   return [.medicine, .religion]
        case .ranger:   return [.nature, .survival, .perception]
        case .bard:     return [.performance, .persuasion, .deception]
        }
    }
}

// MARK: - 屬性 (Abilities)

enum Ability: String, Codable, CaseIterable {
    case strength     = "力量"
    case dexterity    = "敏捷"
    case constitution = "體質"
    case intelligence = "智力"
    case wisdom       = "感知"
    case charisma     = "魅力"

    var abbreviation: String {
        switch self {
        case .strength:     return "STR"
        case .dexterity:    return "DEX"
        case .constitution: return "CON"
        case .intelligence: return "INT"
        case .wisdom:       return "WIS"
        case .charisma:     return "CHA"
        }
    }
}

struct AbilityScores: Codable, Equatable {
    var str: Int
    var dex: Int
    var con: Int
    var int: Int
    var wis: Int
    var cha: Int

    static let base = AbilityScores(str: 10, dex: 10, con: 10, int: 10, wis: 10, cha: 10)

    subscript(ability: Ability) -> Int {
        get {
            switch ability {
            case .strength:     return str
            case .dexterity:    return dex
            case .constitution: return con
            case .intelligence: return int
            case .wisdom:       return wis
            case .charisma:     return cha
            }
        }
        set {
            switch ability {
            case .strength:     str = newValue
            case .dexterity:    dex = newValue
            case .constitution: con = newValue
            case .intelligence: int = newValue
            case .wisdom:       wis = newValue
            case .charisma:     cha = newValue
            }
        }
    }

    /// 屬性調整值 = (屬性值 - 10) / 2
    func modifier(for ability: Ability) -> Int {
        (self[ability] - 10) / 2
    }

    static func + (lhs: AbilityScores, rhs: AbilityScores) -> AbilityScores {
        AbilityScores(
            str: lhs.str + rhs.str,
            dex: lhs.dex + rhs.dex,
            con: lhs.con + rhs.con,
            int: lhs.int + rhs.int,
            wis: lhs.wis + rhs.wis,
            cha: lhs.cha + rhs.cha
        )
    }
}

// MARK: - 技能 (Skills)

enum Skill: String, Codable, CaseIterable {
    case acrobatics    = "特技"
    case arcana        = "奧秘"
    case athletics     = "運動"
    case deception     = "欺瞞"
    case history       = "歷史"
    case insight       = "洞察"
    case intimidation  = "威嚇"
    case investigation = "調查"
    case medicine      = "醫藥"
    case nature        = "自然"
    case perception    = "感知"
    case performance   = "表演"
    case persuasion    = "說服"
    case religion      = "宗教"
    case sleightOfHand = "巧手"
    case stealth       = "匿蹤"
    case survival      = "生存"

    var relatedAbility: Ability {
        switch self {
        case .acrobatics, .sleightOfHand, .stealth:
            return .dexterity
        case .arcana, .history, .investigation, .nature, .religion:
            return .intelligence
        case .athletics:
            return .strength
        case .insight, .medicine, .perception, .survival:
            return .wisdom
        case .deception, .intimidation, .performance, .persuasion:
            return .charisma
        }
    }
}

// MARK: - 玩家角色 (Player Character)

struct PlayerCharacter: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    var race: Race
    var characterClass: CharacterClass
    var level: Int
    var experience: Int
    var abilities: AbilityScores
    var currentHP: Int
    var maxHP: Int
    var armorClass: Int
    var proficiencyBonus: Int
    var skills: [Skill]
    var inventory: [Item]
    var equippedWeapon: Weapon?
    var equippedArmor: Armor?
    var spellSlots: [Int]         // 每等級法術欄位數
    var knownSpells: [Spell]
    var position: GridPosition
    var gold: Int

    /// 先攻值
    var initiativeModifier: Int {
        abilities.modifier(for: .dexterity)
    }

    /// 熟練加值（依等級計算）
    var computedProficiencyBonus: Int {
        (level - 1) / 4 + 2
    }

    /// 建立新角色
    static func create(
        name: String,
        race: Race,
        characterClass: CharacterClass,
        abilities: AbilityScores
    ) -> PlayerCharacter {
        let totalAbilities = abilities + race.abilityBonuses
        let conMod = totalAbilities.modifier(for: .constitution)
        let maxHP = characterClass.hitDie + conMod

        return PlayerCharacter(
            id: UUID(),
            name: name,
            race: race,
            characterClass: characterClass,
            level: 1,
            experience: 0,
            abilities: totalAbilities,
            currentHP: maxHP,
            maxHP: maxHP,
            armorClass: 10 + totalAbilities.modifier(for: .dexterity),
            proficiencyBonus: 2,
            skills: characterClass.startingSkills,
            inventory: [],
            equippedWeapon: nil,
            equippedArmor: nil,
            spellSlots: characterClass == .fighter || characterClass == .rogue ? [] : [2],
            knownSpells: [],
            position: GridPosition(x: 0, y: 0),
            gold: 50
        )
    }

    /// 升級
    mutating func levelUp() {
        level += 1
        let conMod = abilities.modifier(for: .constitution)
        let hpGain = max(1, DiceEngine.roll(.d(characterClass.hitDie)).total + conMod)
        maxHP += hpGain
        currentHP = maxHP
        proficiencyBonus = computedProficiencyBonus
    }

    /// 受傷
    mutating func takeDamage(_ amount: Int) {
        currentHP = max(0, currentHP - amount)
    }

    /// 治療
    mutating func heal(_ amount: Int) {
        currentHP = min(maxHP, currentHP + amount)
    }

    var isAlive: Bool { currentHP > 0 }
}
