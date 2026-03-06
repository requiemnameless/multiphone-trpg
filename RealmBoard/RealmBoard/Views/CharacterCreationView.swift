import SwiftUI

/// 角色建立畫面
struct CharacterCreationView: View {
    @EnvironmentObject var coordinator: GameCoordinator
    @State private var name = ""
    @State private var selectedRace: Race = .human
    @State private var selectedClass: CharacterClass = .fighter
    @State private var abilities = AbilityScores.base
    @State private var remainingPoints = 27  // 購點法
    @State private var currentStep = 0

    var body: some View {
        ZStack {
            Color(hex: "1a1a2e").ignoresSafeArea()

            TabView(selection: $currentStep) {
                // 步驟 1: 種族選擇
                raceSelectionView
                    .tag(0)

                // 步驟 2: 職業選擇
                classSelectionView
                    .tag(1)

                // 步驟 3: 屬性分配
                abilityScoreView
                    .tag(2)

                // 步驟 4: 確認
                confirmationView
                    .tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
        }
    }

    // MARK: - 種族選擇

    private var raceSelectionView: some View {
        ScrollView {
            VStack(spacing: 20) {
                sectionHeader("選擇種族", subtitle: "每個種族擁有不同的屬性加成與特殊能力")

                ForEach(Race.allCases) { race in
                    raceCard(race)
                }
            }
            .padding()
        }
    }

    private func raceCard(_ race: Race) -> some View {
        Button {
            selectedRace = race
        } label: {
            HStack(spacing: 16) {
                Text(raceEmoji(race))
                    .font(.system(size: 40))

                VStack(alignment: .leading, spacing: 4) {
                    Text(race.rawValue)
                        .font(.headline)
                        .foregroundColor(.white)
                    Text(race.description)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .lineLimit(2)
                    Text("速度: \(race.speed) 呎")
                        .font(.caption2)
                        .foregroundColor(.blue)
                }

                Spacer()

                if selectedRace == race {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title2)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(selectedRace == race ? Color.blue.opacity(0.2) : Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(selectedRace == race ? Color.blue : Color.clear, lineWidth: 2)
                    )
            )
        }
    }

    // MARK: - 職業選擇

    private var classSelectionView: some View {
        ScrollView {
            VStack(spacing: 20) {
                sectionHeader("選擇職業", subtitle: "職業決定你的戰鬥風格和技能")

                ForEach(CharacterClass.allCases) { cls in
                    classCard(cls)
                }
            }
            .padding()
        }
    }

    private func classCard(_ cls: CharacterClass) -> some View {
        Button {
            selectedClass = cls
        } label: {
            HStack(spacing: 16) {
                Text(classEmoji(cls))
                    .font(.system(size: 40))

                VStack(alignment: .leading, spacing: 4) {
                    Text(cls.rawValue)
                        .font(.headline)
                        .foregroundColor(.white)
                    Text(cls.description)
                        .font(.caption)
                        .foregroundColor(.gray)
                    HStack {
                        Text("HD: d\(cls.hitDie)")
                            .font(.caption2)
                            .foregroundColor(.red)
                        Text("主屬: \(cls.primaryAbility.rawValue)")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                }

                Spacer()

                if selectedClass == cls {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title2)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(selectedClass == cls ? Color.purple.opacity(0.2) : Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(selectedClass == cls ? Color.purple : Color.clear, lineWidth: 2)
                    )
            )
        }
    }

    // MARK: - 屬性分配

    private var abilityScoreView: some View {
        ScrollView {
            VStack(spacing: 20) {
                sectionHeader("分配屬性", subtitle: "剩餘點數: \(remainingPoints)")

                ForEach(Ability.allCases, id: \.self) { ability in
                    abilityRow(ability)
                }

                Text("種族加成將在確認後自動套用")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding()
        }
    }

    private func abilityRow(_ ability: Ability) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(ability.rawValue)
                    .font(.headline)
                    .foregroundColor(.white)
                Text(ability.abbreviation)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .frame(width: 80, alignment: .leading)

            Spacer()

            Button {
                decreaseAbility(ability)
            } label: {
                Image(systemName: "minus.circle.fill")
                    .font(.title2)
                    .foregroundColor(.red)
            }
            .disabled(abilities[ability] <= 8)

            Text("\(abilities[ability])")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 50)
                .monospacedDigit()

            Button {
                increaseAbility(ability)
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundColor(.green)
            }
            .disabled(remainingPoints <= 0 || abilities[ability] >= 15)

            // 調整值
            let mod = (abilities[ability] - 10) / 2
            Text(mod >= 0 ? "+\(mod)" : "\(mod)")
                .font(.caption)
                .foregroundColor(mod >= 0 ? .green : .red)
                .frame(width: 30)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.05))
        .cornerRadius(8)
    }

    // MARK: - 確認畫面

    private var confirmationView: some View {
        ScrollView {
            VStack(spacing: 20) {
                sectionHeader("確認角色", subtitle: "檢查你的冒險者資訊")

                // 名稱輸入
                TextField("角色名稱", text: $name)
                    .textFieldStyle(.plain)
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)
                    .foregroundColor(.white)
                    .font(.title2)
                    .padding(.horizontal)

                // 角色預覽
                VStack(spacing: 12) {
                    HStack {
                        Text(raceEmoji(selectedRace))
                            .font(.system(size: 60))
                        Text(classEmoji(selectedClass))
                            .font(.system(size: 60))
                    }

                    Text("\(selectedRace.rawValue) \(selectedClass.rawValue)")
                        .font(.title2)
                        .foregroundColor(.white)

                    let finalAbilities = abilities + selectedRace.abilityBonuses
                    let conMod = finalAbilities.modifier(for: .constitution)
                    let maxHP = selectedClass.hitDie + conMod

                    HStack(spacing: 20) {
                        statBadge("HP", value: "\(maxHP)", color: .red)
                        statBadge("AC", value: "\(10 + finalAbilities.modifier(for: .dexterity))", color: .blue)
                        statBadge("速度", value: "\(selectedRace.speed)", color: .green)
                    }

                    // 屬性摘要
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                        ForEach(Ability.allCases, id: \.self) { ability in
                            let bonus = selectedRace.abilityBonuses[ability]
                            let total = abilities[ability] + bonus
                            VStack {
                                Text(ability.abbreviation)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                Text("\(total)")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                if bonus > 0 {
                                    Text("+\(bonus) 種族")
                                        .font(.caption2)
                                        .foregroundColor(.green)
                                }
                            }
                            .padding(8)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(8)
                        }
                    }
                }

                // 建立角色按鈕
                Button {
                    createCharacter()
                } label: {
                    HStack {
                        Image(systemName: "person.badge.plus")
                        Text("開始冒險！")
                    }
                    .font(.headline)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [.yellow, .orange],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                }
                .disabled(name.isEmpty)
                .opacity(name.isEmpty ? 0.5 : 1)
                .padding(.horizontal)
            }
            .padding()
        }
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String, subtitle: String) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .padding(.vertical)
    }

    private func statBadge(_ label: String, value: String, color: Color) -> some View {
        VStack {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(color.opacity(0.15))
        .cornerRadius(8)
    }

    private func increaseAbility(_ ability: Ability) {
        let current = abilities[ability]
        let cost = current >= 13 ? 2 : 1
        guard remainingPoints >= cost, current < 15 else { return }
        abilities[ability] = current + 1
        remainingPoints -= cost
    }

    private func decreaseAbility(_ ability: Ability) {
        let current = abilities[ability]
        guard current > 8 else { return }
        let refund = current > 13 ? 2 : 1
        abilities[ability] = current - 1
        remainingPoints += refund
    }

    private func createCharacter() {
        let character = PlayerCharacter.create(
            name: name,
            race: selectedRace,
            characterClass: selectedClass,
            abilities: abilities
        )
        coordinator.localPlayer = character
        coordinator.allPlayers.append(character)
        coordinator.advancePhase()
    }

    private func raceEmoji(_ race: Race) -> String {
        switch race {
        case .human:      return "🧑"
        case .elf:        return "🧝"
        case .dwarf:      return "🧔"
        case .halfling:   return "🧒"
        case .dragonborn: return "🐲"
        case .tiefling:   return "😈"
        }
    }

    private func classEmoji(_ cls: CharacterClass) -> String {
        switch cls {
        case .fighter:  return "⚔️"
        case .wizard:   return "🧙"
        case .rogue:    return "🗡️"
        case .cleric:   return "✝️"
        case .ranger:   return "🏹"
        case .bard:     return "🎵"
        }
    }
}
