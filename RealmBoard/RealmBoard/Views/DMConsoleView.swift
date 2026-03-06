import SwiftUI

/// 城主 (DM) 控制台 — iPad 專用大螢幕介面
struct DMConsoleView: View {
    @EnvironmentObject var coordinator: GameCoordinator
    @State private var selectedTool: DMTool = .inspect
    @State private var selectedMonsterTemplate: MonsterType = .goblin
    @State private var showNarrationInput = false
    @State private var narrationText = ""
    @State private var selectedTilePos: GridPosition?

    enum DMTool: String, CaseIterable {
        case inspect     = "檢視"
        case placeMonster = "放置怪物"
        case placeTreasure = "放置寶箱"
        case placeTrap   = "放置陷阱"
        case terrain     = "修改地形"
        case fogOfWar    = "迷霧控制"
        case narrate     = "敘事"
    }

    var body: some View {
        HStack(spacing: 0) {
            // 左側：地圖
            mapPanel
                .frame(maxWidth: .infinity)

            // 右側：DM 工具面板
            toolPanel
                .frame(width: 320)
        }
        .background(Color(hex: "0f0f23").ignoresSafeArea())
    }

    // MARK: - 地圖面板

    private var mapPanel: some View {
        VStack(spacing: 0) {
            // DM 頂部資訊列
            HStack {
                Image(systemName: "crown.fill")
                    .foregroundColor(.yellow)
                Text("城主控制台")
                    .font(.headline)
                    .foregroundColor(.yellow)

                Spacer()

                Text("回合 \(coordinator.gameState.currentTurn)")
                    .foregroundColor(.gray)

                Text("·")
                    .foregroundColor(.gray)

                Text("\(coordinator.allPlayers.count) 位玩家")
                    .foregroundColor(.gray)

                Text("·")
                    .foregroundColor(.gray)

                Text("\(coordinator.gameState.monsters.count) 隻怪物")
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color.black.opacity(0.8))

            // 完整地圖（DM 看到所有格子，無迷霧）
            ScrollView([.horizontal, .vertical]) {
                let map = coordinator.gameState.map

                LazyVGrid(
                    columns: Array(repeating: GridItem(.fixed(40), spacing: 1), count: map.width),
                    spacing: 1
                ) {
                    ForEach(0..<map.height, id: \.self) { y in
                        ForEach(0..<map.width, id: \.self) { x in
                            let pos = GridPosition(x: x, y: y)
                            dmTileView(map.tiles[y][x], at: pos)
                        }
                    }
                }
                .padding(8)
            }
        }
    }

    private func dmTileView(_ tile: MapTile, at pos: GridPosition) -> some View {
        let isSelected = selectedTilePos == pos
        let player = coordinator.allPlayers.first { $0.position == pos }
        let monster = coordinator.gameState.monsters.first { $0.position == pos }

        return Button {
            handleDMTileTap(pos)
        } label: {
            ZStack {
                Rectangle()
                    .fill(dmTerrainColor(tile.terrain))

                Text(tile.terrain.symbol)
                    .font(.system(size: 16))

                if let player {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 14, height: 14)
                        .overlay(
                            Text(String(player.name.prefix(1)))
                                .font(.system(size: 8))
                                .foregroundColor(.white)
                        )
                }

                if let monster {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 14, height: 14)
                        .overlay(
                            Text(String(monster.name.prefix(1)))
                                .font(.system(size: 8))
                                .foregroundColor(.white)
                        )
                }

                if tile.trapType != nil {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 8))
                        .foregroundColor(.orange)
                        .offset(x: 10, y: 10)
                }

                if isSelected {
                    Rectangle()
                        .stroke(Color.yellow, lineWidth: 2)
                }
            }
        }
        .frame(width: 40, height: 40)
    }

    // MARK: - DM 工具面板

    private var toolPanel: some View {
        VStack(spacing: 0) {
            // 工具選擇
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(DMTool.allCases, id: \.self) { tool in
                        Button {
                            selectedTool = tool
                        } label: {
                            Text(tool.rawValue)
                                .font(.caption)
                                .foregroundColor(selectedTool == tool ? .black : .white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(selectedTool == tool ? Color.yellow : Color.white.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                }
                .padding()
            }
            .background(Color.black.opacity(0.5))

            Divider()
                .background(Color.gray)

            // 工具內容
            ScrollView {
                switch selectedTool {
                case .inspect:
                    inspectPanel
                case .placeMonster:
                    monsterPanel
                case .placeTreasure:
                    treasurePanel
                case .placeTrap:
                    trapPanel
                case .terrain:
                    terrainPanel
                case .fogOfWar:
                    fogPanel
                case .narrate:
                    narratePanel
                }
            }

            Divider()
                .background(Color.gray)

            // 快速行動
            HStack(spacing: 12) {
                dmQuickButton("開始戰鬥", icon: "bolt.fill", color: .red) {
                    coordinator.combatEngine.startCombat(
                        players: coordinator.allPlayers,
                        monsters: coordinator.gameState.monsters
                    )
                    coordinator.phase = .combat
                    coordinator.broadcastState()
                }

                dmQuickButton("結束戰鬥", icon: "flag.fill", color: .green) {
                    coordinator.combatEngine.endCombat()
                    coordinator.phase = .adventure
                    coordinator.broadcastState()
                }
            }
            .padding()
        }
        .background(Color(hex: "151530"))
    }

    // MARK: - 檢視面板

    private var inspectPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let pos = selectedTilePos {
                Text("位置: (\(pos.x), \(pos.y))")
                    .foregroundColor(.white)

                if let tile = coordinator.gameState.map.tile(at: pos) {
                    Text("地形: \(tile.terrain.rawValue)")
                        .foregroundColor(.gray)
                    Text("可通行: \(tile.isPassable ? "是" : "否")")
                        .foregroundColor(.gray)
                }

                // 顯示此格的角色或怪物
                if let player = coordinator.allPlayers.first(where: { $0.position == pos }) {
                    playerInfoCard(player)
                }
                if let monster = coordinator.gameState.monsters.first(where: { $0.position == pos }) {
                    monsterInfoCard(monster)
                }
            } else {
                Text("點選地圖格子以檢視")
                    .foregroundColor(.gray)
            }
        }
        .padding()
    }

    // MARK: - 怪物放置面板

    private var monsterPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("選擇怪物")
                .font(.headline)
                .foregroundColor(.white)

            ForEach(MonsterType.allCases, id: \.self) { type in
                Button {
                    selectedMonsterTemplate = type
                } label: {
                    HStack {
                        Text(type.rawValue)
                            .foregroundColor(selectedMonsterTemplate == type ? .yellow : .white)
                        Spacer()
                        if selectedMonsterTemplate == type {
                            Image(systemName: "checkmark")
                                .foregroundColor(.yellow)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            Text("選擇後點選地圖放置怪物")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
    }

    private var treasurePanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("寶箱內容")
                .font(.headline)
                .foregroundColor(.white)
            Text("點選地圖格子放置寶箱")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
    }

    private var trapPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("陷阱類型")
                .font(.headline)
                .foregroundColor(.white)

            ForEach(TrapType.allCases, id: \.self) { trap in
                HStack {
                    Text(trap.rawValue)
                        .foregroundColor(.white)
                    Spacer()
                    Text("DC \(trap.detectionDC)")
                        .font(.caption)
                        .foregroundColor(.orange)
                    Text(trap.damage)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
        .padding()
    }

    private var terrainPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("地形筆刷")
                .font(.headline)
                .foregroundColor(.white)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                ForEach(TerrainType.allCases, id: \.self) { terrain in
                    Button {
                        // 設定筆刷地形
                    } label: {
                        VStack {
                            Text(terrain.symbol)
                                .font(.title3)
                            Text(terrain.rawValue)
                                .font(.caption2)
                                .foregroundColor(.white)
                        }
                        .padding(8)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
            }
        }
        .padding()
    }

    private var fogPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("戰爭迷霧")
                .font(.headline)
                .foregroundColor(.white)

            Button("揭露所有") {
                // 揭露整張地圖
            }
            .foregroundColor(.green)

            Button("重設迷霧") {
                // 重新覆蓋迷霧
            }
            .foregroundColor(.red)
        }
        .padding()
    }

    private var narratePanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("DM 敘事")
                .font(.headline)
                .foregroundColor(.white)

            TextEditor(text: $narrationText)
                .frame(height: 120)
                .cornerRadius(8)

            Button {
                broadcastNarration()
            } label: {
                Text("發送敘事")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
        }
        .padding()
    }

    // MARK: - 資訊卡片

    private func playerInfoCard(_ player: PlayerCharacter) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(player.name)
                .font(.headline)
                .foregroundColor(.blue)
            Text("\(player.race.rawValue) \(player.characterClass.rawValue) Lv.\(player.level)")
                .font(.caption)
                .foregroundColor(.gray)
            Text("HP: \(player.currentHP)/\(player.maxHP) | AC: \(player.armorClass)")
                .font(.caption)
                .foregroundColor(.white)
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(8)
    }

    private func monsterInfoCard(_ monster: Monster) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(monster.name)
                .font(.headline)
                .foregroundColor(.red)
            Text("CR \(monster.challengeRating, specifier: "%.1f") | \(monster.difficulty.rawValue)")
                .font(.caption)
                .foregroundColor(.gray)
            Text("HP: \(monster.currentHP)/\(monster.maxHP) | AC: \(monster.armorClass)")
                .font(.caption)
                .foregroundColor(.white)
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(8)
    }

    // MARK: - Helpers

    private func dmQuickButton(_ label: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                Text(label)
                    .font(.caption2)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(color.opacity(0.6))
            .cornerRadius(8)
        }
    }

    private func handleDMTileTap(_ pos: GridPosition) {
        selectedTilePos = pos

        switch selectedTool {
        case .placeMonster:
            placeMonster(at: pos)
        case .placeTreasure:
            placeTreasure(at: pos)
        default:
            break
        }
    }

    private func placeMonster(at pos: GridPosition) {
        let monster: Monster
        switch selectedMonsterTemplate {
        case .goblin:   monster = .goblin(at: pos)
        case .skeleton: monster = .skeleton(at: pos)
        case .orc:      monster = .orc(at: pos)
        case .dragon:   monster = .dragon(at: pos)
        default:        monster = .goblin(at: pos)
        }
        coordinator.gameState.monsters.append(monster)
        coordinator.broadcastState()
    }

    private func placeTreasure(at pos: GridPosition) {
        if var tile = coordinator.gameState.map.tile(at: pos) {
            tile.occupant = .chest
            tile.lootItems = [Item.healthPotion(), Item.torch()]
            coordinator.gameState.map.setTile(tile, at: pos)
            coordinator.broadcastState()
        }
    }

    private func broadcastNarration() {
        guard !narrationText.isEmpty else { return }
        let msg = GameMessage(
            type: .chatMessage,
            payload: .chat(ChatData(senderName: "城主", message: narrationText, isNarration: true))
        )
        coordinator.sessionManager.broadcast(msg)
        narrationText = ""
    }

    private func dmTerrainColor(_ terrain: TerrainType) -> Color {
        switch terrain {
        case .grass:    return Color(hex: "2d5a27")
        case .stone:    return Color(hex: "696969")
        case .water:    return Color(hex: "1e90ff").opacity(0.6)
        case .lava:     return Color(hex: "ff4500").opacity(0.8)
        case .forest:   return Color(hex: "1a4314")
        case .mountain: return Color(hex: "8b7355")
        case .sand:     return Color(hex: "c2b280")
        case .snow:     return Color(hex: "e8e8e8")
        case .dungeon:  return Color(hex: "3a3a3a")
        case .wall:     return Color(hex: "4a4a4a")
        case .door:     return Color(hex: "8b4513")
        case .void:     return Color(hex: "0a0a0a")
        }
    }
}

// MARK: - TrapType CaseIterable
extension TrapType: CaseIterable {
    static var allCases: [TrapType] {
        [.pitTrap, .poisonDart, .fireTrap, .alarmTrap, .magicRune]
    }
}
