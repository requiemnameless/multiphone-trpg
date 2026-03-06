import SwiftUI

/// 戰鬥畫面 — 回合制 D&D 戰鬥介面
struct CombatView: View {
    @EnvironmentObject var coordinator: GameCoordinator
    @State private var selectedAction: CombatActionType?
    @State private var selectedTarget: UUID?
    @State private var showSpellList = false

    var combatEngine: CombatEngine { coordinator.combatEngine }

    var body: some View {
        ZStack {
            Color(hex: "1a0a0a").ignoresSafeArea()

            VStack(spacing: 0) {
                // 回合順序列
                turnOrderBar

                // 戰鬥地圖
                combatMapArea
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                // 戰鬥日誌
                combatLogView
                    .frame(height: 100)

                // 行動選單
                actionMenu
            }
        }
    }

    // MARK: - 回合順序

    private var turnOrderBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(combatEngine.turnOrder.enumerated()), id: \.element.id) { index, combatant in
                    VStack(spacing: 4) {
                        // 圓形頭像
                        Circle()
                            .fill(combatant.type == .player ? Color.blue : Color.red)
                            .frame(width: 40, height: 40)
                            .overlay(
                                Text(String(combatant.name.prefix(1)))
                                    .font(.headline)
                                    .foregroundColor(.white)
                            )
                            .overlay(
                                Circle()
                                    .stroke(
                                        index == combatEngine.currentTurnIndex ? Color.yellow : Color.clear,
                                        lineWidth: 3
                                    )
                            )

                        Text(combatant.name)
                            .font(.caption2)
                            .foregroundColor(.white)
                            .lineLimit(1)

                        // HP
                        Text("\(combatant.currentHP)")
                            .font(.caption2)
                            .foregroundColor(combatant.currentHP > 0 ? .green : .red)
                    }
                    .opacity(combatant.currentHP > 0 ? 1 : 0.4)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.8))
    }

    // MARK: - 戰鬥地圖

    private var combatMapArea: some View {
        ScrollView([.horizontal, .vertical]) {
            let map = coordinator.gameState.map

            LazyVGrid(
                columns: Array(repeating: GridItem(.fixed(50), spacing: 1), count: map.width),
                spacing: 1
            ) {
                ForEach(0..<map.height, id: \.self) { y in
                    ForEach(0..<map.width, id: \.self) { x in
                        let pos = GridPosition(x: x, y: y)
                        combatTileView(map.tiles[y][x], at: pos)
                    }
                }
            }
            .padding(8)
        }
    }

    private func combatTileView(_ tile: MapTile, at pos: GridPosition) -> some View {
        let player = coordinator.allPlayers.first { $0.position == pos }
        let monster = coordinator.gameState.monsters.first { $0.position == pos }
        let isTargetable = monster != nil && selectedAction == .attack

        return Button {
            if let monster {
                selectedTarget = monster.id
            }
        } label: {
            ZStack {
                Rectangle()
                    .fill(tile.terrain.isPassable ? Color(hex: "2a2a2a") : Color(hex: "1a1a1a"))

                if let player {
                    ZStack {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 30, height: 30)
                        Text(String(player.name.prefix(1)))
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                }

                if let monster {
                    ZStack {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 30, height: 30)
                        Text(String(monster.name.prefix(1)))
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                }

                if isTargetable {
                    Rectangle()
                        .stroke(Color.red, lineWidth: 2)
                }

                if selectedTarget == monster?.id {
                    Rectangle()
                        .stroke(Color.yellow, lineWidth: 3)
                }
            }
        }
        .frame(width: 50, height: 50)
    }

    // MARK: - 戰鬥日誌

    private var combatLogView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 4) {
                    ForEach(combatEngine.combatLog) { entry in
                        Text(entry.message)
                            .font(.caption)
                            .foregroundColor(.gray)
                            .id(entry.id)
                    }
                }
                .padding(.horizontal)
            }
            .background(Color.black.opacity(0.6))
            .onChange(of: combatEngine.combatLog.count) { _, _ in
                if let last = combatEngine.combatLog.last {
                    proxy.scrollTo(last.id, anchor: .bottom)
                }
            }
        }
    }

    // MARK: - 行動選單

    private var actionMenu: some View {
        VStack(spacing: 8) {
            // 當前回合資訊
            if let current = combatEngine.currentCombatant {
                HStack {
                    Text("回合 \(combatEngine.roundNumber)")
                        .font(.caption)
                        .foregroundColor(.yellow)
                    Spacer()
                    Text("\(current.name) 的回合")
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding(.horizontal)
            }

            // 行動按鈕
            HStack(spacing: 12) {
                combatButton("攻擊", icon: "bolt.fill", color: .red) {
                    selectedAction = .attack
                }

                combatButton("施法", icon: "wand.and.stars", color: .purple) {
                    showSpellList = true
                }

                combatButton("迴避", icon: "shield.fill", color: .blue) {
                    selectedAction = .dodge
                }

                combatButton("結束", icon: "arrow.right.circle.fill", color: .gray) {
                    combatEngine.nextTurn()
                }
            }
            .padding(.horizontal)

            // 確認攻擊
            if selectedAction == .attack, selectedTarget != nil {
                Button {
                    executeAttack()
                } label: {
                    Text("確認攻擊！")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.9))
    }

    private func combatButton(_ label: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title3)
                Text(label)
                    .font(.caption)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(color.opacity(0.6))
            .cornerRadius(12)
        }
    }

    // MARK: - 執行攻擊

    private func executeAttack() {
        guard let player = coordinator.localPlayer,
              let targetId = selectedTarget,
              var monster = coordinator.gameState.monsters.first(where: { $0.id == targetId })
        else { return }

        _ = combatEngine.performAttack(
            attacker: player,
            target: &monster,
            weapon: player.equippedWeapon
        )

        // 更新怪物狀態
        if let idx = coordinator.gameState.monsters.firstIndex(where: { $0.id == targetId }) {
            coordinator.gameState.monsters[idx] = monster
        }

        selectedAction = nil
        selectedTarget = nil

        // 同步狀態
        coordinator.broadcastState()
    }
}
