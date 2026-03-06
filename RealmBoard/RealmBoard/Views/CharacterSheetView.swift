import SwiftUI

/// 角色資料表 — 顯示完整的 D&D 角色資訊
struct CharacterSheetView: View {
    let character: PlayerCharacter
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 基本資訊
                    headerSection

                    // 屬性值
                    abilityScoresSection

                    // 戰鬥數值
                    combatStatsSection

                    // 技能
                    skillsSection

                    // 法術（如果有）
                    if !character.knownSpells.isEmpty {
                        spellsSection
                    }
                }
                .padding()
            }
            .background(Color(hex: "1a1a2e").ignoresSafeArea())
            .navigationTitle("角色資料表")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("關閉") { dismiss() }
                }
            }
        }
    }

    // MARK: - 標題區

    private var headerSection: some View {
        VStack(spacing: 8) {
            Text(character.name)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Text("\(character.race.rawValue) \(character.characterClass.rawValue)")
                .font(.title3)
                .foregroundColor(.gray)

            HStack(spacing: 20) {
                VStack {
                    Text("等級")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("\(character.level)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.yellow)
                }
                VStack {
                    Text("經驗")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("\(character.experience)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
                VStack {
                    Text("金幣")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("\(character.gold)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }

    // MARK: - 屬性值

    private var abilityScoresSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("屬性值")
                .font(.headline)
                .foregroundColor(.white)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                ForEach(Ability.allCases, id: \.self) { ability in
                    VStack(spacing: 4) {
                        Text(ability.abbreviation)
                            .font(.caption)
                            .foregroundColor(.gray)

                        let value = character.abilities[ability]
                        Text("\(value)")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)

                        let mod = character.abilities.modifier(for: ability)
                        Text(mod >= 0 ? "+\(mod)" : "\(mod)")
                            .font(.subheadline)
                            .foregroundColor(mod >= 0 ? .green : .red)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(8)
                    }
                    .padding()
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(12)
                }
            }
        }
    }

    // MARK: - 戰鬥數值

    private var combatStatsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("戰鬥數值")
                .font(.headline)
                .foregroundColor(.white)

            HStack(spacing: 16) {
                combatStat("HP", value: "\(character.currentHP)/\(character.maxHP)", color: .red)
                combatStat("AC", value: "\(character.armorClass)", color: .blue)
                combatStat("先攻", value: "+\(character.initiativeModifier)", color: .orange)
                combatStat("熟練", value: "+\(character.proficiencyBonus)", color: .purple)
            }

            if let weapon = character.equippedWeapon {
                HStack {
                    Image(systemName: "bolt.fill")
                        .foregroundColor(.yellow)
                    Text("武器: \(weapon.name) (\(weapon.damage) \(weapon.damageType.rawValue))")
                        .foregroundColor(.white)
                }
            }

            if let armor = character.equippedArmor {
                HStack {
                    Image(systemName: "shield.fill")
                        .foregroundColor(.blue)
                    Text("護甲: \(armor.name) (AC \(armor.baseAC))")
                        .foregroundColor(.white)
                }
            }
        }
    }

    private func combatStat(_ label: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }

    // MARK: - 技能

    private var skillsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("技能")
                .font(.headline)
                .foregroundColor(.white)

            ForEach(character.skills, id: \.self) { skill in
                HStack {
                    let isProficient = true
                    Image(systemName: isProficient ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isProficient ? .green : .gray)
                    Text(skill.rawValue)
                        .foregroundColor(.white)
                    Spacer()
                    let mod = character.abilities.modifier(for: skill.relatedAbility) +
                        (isProficient ? character.proficiencyBonus : 0)
                    Text(mod >= 0 ? "+\(mod)" : "\(mod)")
                        .foregroundColor(.yellow)
                }
            }
        }
    }

    // MARK: - 法術

    private var spellsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("已知法術")
                .font(.headline)
                .foregroundColor(.white)

            ForEach(character.knownSpells) { spell in
                HStack {
                    VStack(alignment: .leading) {
                        Text(spell.name)
                            .foregroundColor(.white)
                            .fontWeight(.semibold)
                        Text(spell.isCantrip ? "戲法" : "等級 \(spell.level)")
                            .font(.caption)
                            .foregroundColor(.purple)
                    }
                    Spacer()
                    if let dmg = spell.damage {
                        Text(dmg)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    if let heal = spell.healing {
                        Text(heal)
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }
}
