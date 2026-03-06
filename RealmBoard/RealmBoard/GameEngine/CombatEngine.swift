import Foundation
import Combine

/// 戰鬥引擎 — 處理 D&D 風格的回合制戰鬥
@MainActor
final class CombatEngine: ObservableObject {
    @Published var isActive = false
    @Published var turnOrder: [CombatantInfo] = []
    @Published var currentTurnIndex: Int = 0
    @Published var roundNumber: Int = 0
    @Published var combatLog: [CombatLogEntry] = []

    var currentCombatant: CombatantInfo? {
        guard !turnOrder.isEmpty, currentTurnIndex < turnOrder.count else { return nil }
        return turnOrder[currentTurnIndex]
    }

    // MARK: - 開始戰鬥

    func startCombat(players: [PlayerCharacter], monsters: [Monster]) {
        isActive = true
        roundNumber = 1
        combatLog.removeAll()

        // 擲先攻
        var combatants: [CombatantInfo] = []

        for player in players where player.isAlive {
            let initiative = DiceEngine.initiativeRoll(modifier: player.initiativeModifier)
            combatants.append(CombatantInfo(
                id: player.id,
                name: player.name,
                type: .player,
                initiative: initiative.total,
                currentHP: player.currentHP,
                maxHP: player.maxHP,
                armorClass: player.armorClass
            ))
            log("🎲 \(player.name) 先攻: \(initiative.total) (\(initiative.rolls.first ?? 0) + \(player.initiativeModifier))")
        }

        for monster in monsters where monster.isAlive {
            let initiative = DiceEngine.initiativeRoll(modifier: monster.initiativeModifier)
            combatants.append(CombatantInfo(
                id: monster.id,
                name: monster.name,
                type: .monster,
                initiative: initiative.total,
                currentHP: monster.currentHP,
                maxHP: monster.maxHP,
                armorClass: monster.armorClass
            ))
            log("🎲 \(monster.name) 先攻: \(initiative.total)")
        }

        // 依先攻排序（高到低）
        turnOrder = combatants.sorted { $0.initiative > $1.initiative }
        currentTurnIndex = 0

        log("⚔️ ====== 戰鬥開始！第 \(roundNumber) 回合 ======")
        if let first = currentCombatant {
            log("▶️ 輪到 \(first.name) 行動")
        }
    }

    // MARK: - 攻擊

    func performAttack(
        attacker: PlayerCharacter,
        target: inout Monster,
        weapon: Weapon?
    ) -> AttackResult {
        let wpn = weapon ?? .longsword()
        let abilityMod = wpn.isMelee
            ? attacker.abilities.modifier(for: .strength)
            : attacker.abilities.modifier(for: .dexterity)
        let attackBonus = abilityMod + attacker.proficiencyBonus

        // 攻擊擲骰
        let attackRoll = DiceEngine.attackRoll(attackBonus: attackBonus)
        let hit = attackRoll.total >= target.armorClass || attackRoll.isCriticalHit

        var totalDamage = 0
        var damageResult: DiceResult?

        if hit && !attackRoll.isCriticalMiss {
            // 傷害擲骰
            if let parsed = DiceEngine.parseDiceString(wpn.damage) {
                let diceCount = attackRoll.isCriticalHit ? parsed.count * 2 : parsed.count
                let dmgRoll = DiceEngine.roll(diceCount, parsed.die, modifier: abilityMod, purpose: "傷害")
                totalDamage = dmgRoll.total
                damageResult = dmgRoll
            }
            target.takeDamage(totalDamage)

            if attackRoll.isCriticalHit {
                log("💥 爆擊！\(attacker.name) 用 \(wpn.name) 攻擊 \(target.name)！命中 (\(attackRoll.total) vs AC \(target.armorClass))，造成 \(totalDamage) 點\(wpn.damageType.rawValue)傷害！")
            } else {
                log("⚔️ \(attacker.name) 用 \(wpn.name) 攻擊 \(target.name)！命中 (\(attackRoll.total) vs AC \(target.armorClass))，造成 \(totalDamage) 點\(wpn.damageType.rawValue)傷害。")
            }

            if !target.isAlive {
                log("💀 \(target.name) 被擊敗！獲得 \(target.experienceReward) 經驗值！")
            }
        } else {
            if attackRoll.isCriticalMiss {
                log("😱 大失敗！\(attacker.name) 的攻擊完全落空！")
            } else {
                log("🛡️ \(attacker.name) 攻擊 \(target.name) 但未命中 (\(attackRoll.total) vs AC \(target.armorClass))。")
            }
        }

        return AttackResult(
            hit: hit,
            criticalHit: attackRoll.isCriticalHit,
            criticalMiss: attackRoll.isCriticalMiss,
            attackRoll: attackRoll,
            damageRoll: damageResult,
            totalDamage: totalDamage,
            targetDefeated: !target.isAlive
        )
    }

    // MARK: - 怪物攻擊玩家

    func performMonsterAttack(
        monster: Monster,
        attack: MonsterAttack,
        target: inout PlayerCharacter
    ) -> AttackResult {
        let attackRoll = DiceEngine.attackRoll(attackBonus: attack.toHitBonus)
        let hit = attackRoll.total >= target.armorClass || attackRoll.isCriticalHit

        var totalDamage = 0
        var damageResult: DiceResult?

        if hit && !attackRoll.isCriticalMiss {
            if let parsed = DiceEngine.parseDiceString(attack.damage) {
                let diceCount = attackRoll.isCriticalHit ? parsed.count * 2 : parsed.count
                let dmgRoll = DiceEngine.roll(diceCount, parsed.die, modifier: parsed.modifier, purpose: "傷害")
                totalDamage = dmgRoll.total
                damageResult = dmgRoll
            }
            target.takeDamage(totalDamage)

            log("🗡️ \(monster.name) 用 \(attack.name) 攻擊 \(target.name)！造成 \(totalDamage) 點傷害。[\(target.currentHP)/\(target.maxHP) HP]")

            if !target.isAlive {
                log("☠️ \(target.name) 倒下了！")
            }
        } else {
            log("🛡️ \(monster.name) 攻擊 \(target.name) 未命中。")
        }

        return AttackResult(
            hit: hit,
            criticalHit: attackRoll.isCriticalHit,
            criticalMiss: attackRoll.isCriticalMiss,
            attackRoll: attackRoll,
            damageRoll: damageResult,
            totalDamage: totalDamage,
            targetDefeated: !target.isAlive
        )
    }

    // MARK: - 施法

    func castSpell(
        caster: PlayerCharacter,
        spell: Spell,
        target: inout Monster
    ) -> SpellResult {
        guard let damage = spell.damage,
              let parsed = DiceEngine.parseDiceString(damage) else {
            log("✨ \(caster.name) 施放了 \(spell.name)！")
            return SpellResult(success: true, damage: 0, healed: 0)
        }

        let spellMod = caster.abilities.modifier(for: caster.characterClass.primaryAbility)
        let dmgRoll = DiceEngine.roll(parsed.count, parsed.die, modifier: spellMod, purpose: spell.name)
        let totalDmg = dmgRoll.total
        target.takeDamage(totalDmg)

        log("🔮 \(caster.name) 施放 \(spell.name)！對 \(target.name) 造成 \(totalDmg) 點傷害！")

        if !target.isAlive {
            log("💀 \(target.name) 被消滅了！")
        }

        return SpellResult(success: true, damage: totalDmg, healed: 0)
    }

    // MARK: - 治療法術

    func castHealingSpell(
        caster: PlayerCharacter,
        spell: Spell,
        target: inout PlayerCharacter
    ) -> SpellResult {
        guard let healing = spell.healing,
              let parsed = DiceEngine.parseDiceString(healing) else {
            return SpellResult(success: false, damage: 0, healed: 0)
        }

        let spellMod = caster.abilities.modifier(for: caster.characterClass.primaryAbility)
        let healRoll = DiceEngine.roll(parsed.count, parsed.die, modifier: spellMod, purpose: spell.name)
        let healed = healRoll.total
        target.heal(healed)

        log("💚 \(caster.name) 對 \(target.name) 施放 \(spell.name)，恢復 \(healed) HP！[\(target.currentHP)/\(target.maxHP)]")

        return SpellResult(success: true, damage: 0, healed: healed)
    }

    // MARK: - 回合控制

    func nextTurn() {
        currentTurnIndex += 1
        if currentTurnIndex >= turnOrder.count {
            currentTurnIndex = 0
            roundNumber += 1
            log("⚔️ ====== 第 \(roundNumber) 回合 ======")
        }

        // 跳過已死亡的戰鬥者
        if let current = currentCombatant, current.currentHP <= 0 {
            nextTurn()
            return
        }

        if let current = currentCombatant {
            log("▶️ 輪到 \(current.name) 行動")
        }
    }

    func endCombat() {
        isActive = false
        log("🏆 戰鬥結束！")
        turnOrder.removeAll()
        currentTurnIndex = 0
        roundNumber = 0
    }

    // MARK: - 處理遠端戰鬥行動

    func processAction(_ action: CombatAction) {
        // 處理來自其他裝置的戰鬥行動
    }

    func applyDiceResult(_ result: DiceResult) {
        log("🎲 \(result.purpose): \(result.total) [\(result.rolls.map(String.init).joined(separator: ", "))]")
    }

    // MARK: - 戰鬥日誌

    private func log(_ message: String) {
        combatLog.append(CombatLogEntry(message: message))
    }
}

// MARK: - 戰鬥輔助結構

struct CombatantInfo: Codable, Identifiable, Equatable {
    let id: UUID
    let name: String
    let type: CombatantType
    let initiative: Int
    var currentHP: Int
    var maxHP: Int
    var armorClass: Int

    enum CombatantType: String, Codable {
        case player
        case monster
    }
}

struct AttackResult {
    let hit: Bool
    let criticalHit: Bool
    let criticalMiss: Bool
    let attackRoll: DiceResult
    let damageRoll: DiceResult?
    let totalDamage: Int
    let targetDefeated: Bool
}

struct SpellResult {
    let success: Bool
    let damage: Int
    let healed: Int
}

struct CombatLogEntry: Identifiable, Equatable {
    let id = UUID()
    let timestamp = Date()
    let message: String
}
