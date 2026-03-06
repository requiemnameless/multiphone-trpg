import SwiftUI

/// 背包 & 裝備介面
struct InventoryView: View {
    let character: PlayerCharacter
    @Environment(\.dismiss) var dismiss
    @State private var selectedTab = 0

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "1a1a2e").ignoresSafeArea()

                VStack(spacing: 0) {
                    // 分頁
                    Picker("", selection: $selectedTab) {
                        Text("背包").tag(0)
                        Text("武器").tag(1)
                        Text("防具").tag(2)
                    }
                    .pickerStyle(.segmented)
                    .padding()

                    // 金幣
                    HStack {
                        Image(systemName: "circle.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)
                        Text("\(character.gold) 金幣")
                            .foregroundColor(.yellow)
                        Spacer()
                        Text("負重: \(totalWeight, specifier: "%.1f") / \(maxCarry) 磅")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)

                    // 列表
                    ScrollView {
                        switch selectedTab {
                        case 0:
                            inventoryList
                        case 1:
                            weaponSection
                        case 2:
                            armorSection
                        default:
                            EmptyView()
                        }
                    }
                }
            }
            .navigationTitle("背包")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("關閉") { dismiss() }
                }
            }
        }
    }

    // MARK: - 物品列表

    private var inventoryList: some View {
        LazyVStack(spacing: 8) {
            if character.inventory.isEmpty {
                emptyState("背包是空的", icon: "bag")
            } else {
                ForEach(character.inventory) { item in
                    itemRow(item)
                }
            }
        }
        .padding()
    }

    private func itemRow(_ item: Item) -> some View {
        HStack {
            rarityIcon(item.rarity)
            VStack(alignment: .leading) {
                Text(item.name)
                    .foregroundColor(rarityColor(item.rarity))
                    .fontWeight(.semibold)
                Text(item.description)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            Spacer()
            Text("\(item.value) gp")
                .font(.caption)
                .foregroundColor(.yellow)
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }

    // MARK: - 武器

    private var weaponSection: some View {
        VStack(spacing: 12) {
            if let weapon = character.equippedWeapon {
                VStack(alignment: .leading, spacing: 8) {
                    Text("裝備中")
                        .font(.caption)
                        .foregroundColor(.green)

                    HStack {
                        Image(systemName: "bolt.fill")
                            .foregroundColor(.yellow)
                        VStack(alignment: .leading) {
                            Text(weapon.name)
                                .foregroundColor(rarityColor(weapon.rarity))
                                .fontWeight(.bold)
                            Text("\(weapon.damage) \(weapon.damageType.rawValue)")
                                .font(.caption)
                                .foregroundColor(.red)
                            Text(weapon.properties.joined(separator: " · "))
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(12)
            } else {
                emptyState("未裝備武器", icon: "bolt.slash")
            }
        }
        .padding()
    }

    // MARK: - 防具

    private var armorSection: some View {
        VStack(spacing: 12) {
            if let armor = character.equippedArmor {
                VStack(alignment: .leading, spacing: 8) {
                    Text("裝備中")
                        .font(.caption)
                        .foregroundColor(.green)

                    HStack {
                        Image(systemName: "shield.fill")
                            .foregroundColor(.blue)
                        VStack(alignment: .leading) {
                            Text(armor.name)
                                .foregroundColor(rarityColor(armor.rarity))
                                .fontWeight(.bold)
                            Text("AC \(armor.baseAC) · \(armor.type.rawValue)")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
            } else {
                emptyState("未裝備護甲", icon: "shield.slash")
            }
        }
        .padding()
    }

    // MARK: - Helpers

    private func emptyState(_ text: String, icon: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(.gray)
            Text(text)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private func rarityIcon(_ rarity: ItemRarity) -> some View {
        Image(systemName: "diamond.fill")
            .foregroundColor(rarityColor(rarity))
            .font(.caption)
    }

    private func rarityColor(_ rarity: ItemRarity) -> Color {
        switch rarity {
        case .common:    return .white
        case .uncommon:  return .green
        case .rare:      return .blue
        case .veryRare:  return .purple
        case .legendary: return .orange
        }
    }

    private var totalWeight: Double {
        character.inventory.reduce(0) { $0 + $1.weight }
    }

    private var maxCarry: Int {
        character.abilities.str * 15
    }
}
