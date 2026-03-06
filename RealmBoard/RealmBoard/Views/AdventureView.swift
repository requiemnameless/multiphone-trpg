import SwiftUI

/// 冒險探索畫面 — 顯示地圖、角色與互動介面
struct AdventureView: View {
    @EnvironmentObject var coordinator: GameCoordinator
    @State private var showCharacterSheet = false
    @State private var showInventory = false
    @State private var showDiceRoller = false
    @State private var selectedTile: GridPosition?
    @State private var showEventLog = false

    var body: some View {
        ZStack {
            Color(hex: "0f0f23").ignoresSafeArea()

            VStack(spacing: 0) {
                // 頂部 HUD
                topHUD

                // 地圖區域
                mapArea
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                // 底部操作列
                bottomActionBar
            }

            // 事件通知
            if let lastEvent = coordinator.gameState.eventLog.last {
                VStack {
                    eventBanner(lastEvent)
                    Spacer()
                }
            }
        }
        .sheet(isPresented: $showCharacterSheet) {
            CharacterSheetView(character: coordinator.localPlayer ?? .create(
                name: "測試", race: .human, characterClass: .fighter, abilities: .base
            ))
        }
        .sheet(isPresented: $showDiceRoller) {
            DiceRollerView()
        }
        .sheet(isPresented: $showInventory) {
            InventoryView(character: coordinator.localPlayer ?? .create(
                name: "測試", race: .human, characterClass: .fighter, abilities: .base
            ))
        }
    }

    // MARK: - 頂部 HUD

    private var topHUD: some View {
        HStack {
            // 角色資訊
            if let player = coordinator.localPlayer {
                HStack(spacing: 8) {
                    // HP 條
                    VStack(alignment: .leading, spacing: 2) {
                        Text(player.name)
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)

                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                Rectangle()
                                    .fill(hpColor(current: player.currentHP, max: player.maxHP))
                                    .frame(width: geo.size.width * CGFloat(player.currentHP) / CGFloat(player.maxHP))
                            }
                            .cornerRadius(4)
                        }
                        .frame(height: 8)

                        Text("\(player.currentHP)/\(player.maxHP) HP")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                    .frame(width: 120)
                }
            }

            Spacer()

            // 回合 / 地圖資訊
            VStack(alignment: .trailing, spacing: 2) {
                Text(coordinator.gameState.map.name)
                    .font(.caption)
                    .foregroundColor(.gray)
                Text("回合 \(coordinator.gameState.currentTurn)")
                    .font(.caption2)
                    .foregroundColor(.yellow)
            }

            // 連線狀態
            Circle()
                .fill(coordinator.isConnected ? Color.green : Color.orange)
                .frame(width: 8, height: 8)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.8))
    }

    // MARK: - 地圖區域

    private var mapArea: some View {
        ScrollView([.horizontal, .vertical]) {
            let map = coordinator.gameState.map

            LazyVGrid(
                columns: Array(repeating: GridItem(.fixed(44), spacing: 1), count: map.width),
                spacing: 1
            ) {
                ForEach(0..<map.height, id: \.self) { y in
                    ForEach(0..<map.width, id: \.self) { x in
                        let pos = GridPosition(x: x, y: y)
                        tileView(map.tiles[y][x], at: pos)
                    }
                }
            }
            .padding(8)
        }
    }

    private func tileView(_ tile: MapTile, at pos: GridPosition) -> some View {
        let isSelected = selectedTile == pos
        let hasPlayer = coordinator.allPlayers.contains { $0.position == pos }
        let hasMonster = coordinator.gameState.monsters.contains { $0.position == pos }

        return Button {
            handleTileTap(pos)
        } label: {
            ZStack {
                // 地形
                Rectangle()
                    .fill(terrainColor(tile.terrain))

                // 地形符號
                Text(tile.terrain.symbol)
                    .font(.system(size: 20))

                // 角色 / 怪物標記
                if hasPlayer {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 16, height: 16)
                        .overlay(
                            Circle().stroke(Color.white, lineWidth: 1)
                        )
                }

                if hasMonster {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 16, height: 16)
                        .overlay(
                            Circle().stroke(Color.white, lineWidth: 1)
                        )
                }

                // 選取框
                if isSelected {
                    Rectangle()
                        .stroke(Color.yellow, lineWidth: 2)
                }
            }
        }
        .frame(width: 44, height: 44)
    }

    // MARK: - 底部操作列

    private var bottomActionBar: some View {
        HStack(spacing: 0) {
            actionButton(icon: "person.fill", label: "角色") {
                showCharacterSheet = true
            }

            actionButton(icon: "bag.fill", label: "背包") {
                showInventory = true
            }

            actionButton(icon: "dice.fill", label: "擲骰") {
                showDiceRoller = true
            }

            actionButton(icon: "text.bubble.fill", label: "紀錄") {
                showEventLog = true
            }

            if coordinator.deviceRole == .dungeonMaster {
                actionButton(icon: "crown.fill", label: "DM") {
                    // 開啟 DM 面板
                }
            }
        }
        .background(Color.black.opacity(0.9))
    }

    private func actionButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title3)
                Text(label)
                    .font(.caption2)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
    }

    // MARK: - 事件通知

    private func eventBanner(_ event: GameEvent) -> some View {
        Text(event.description)
            .font(.caption)
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.black.opacity(0.7))
            .cornerRadius(20)
            .padding(.top, 60)
    }

    // MARK: - Helpers

    private func handleTileTap(_ pos: GridPosition) {
        if selectedTile == pos {
            // 嘗試移動
            if let player = coordinator.localPlayer {
                let move = MovementData(
                    characterId: player.id,
                    destination: pos,
                    path: [player.position, pos]
                )
                coordinator.gameState.applyMovement(move)
                coordinator.broadcastState()
            }
            selectedTile = nil
        } else {
            selectedTile = pos
        }
    }

    private func terrainColor(_ terrain: TerrainType) -> Color {
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

    private func hpColor(current: Int, max: Int) -> Color {
        let ratio = Double(current) / Double(max)
        if ratio > 0.6 { return .green }
        if ratio > 0.3 { return .yellow }
        return .red
    }
}
