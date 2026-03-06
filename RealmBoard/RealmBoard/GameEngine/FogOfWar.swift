import Foundation

/// 戰爭迷霧系統
///
/// 管理地圖上每個格子的可見性，只有在玩家視線範圍內的格子才會被顯示。
/// 已經探索過但不在視線內的格子會顯示為灰色。
struct FogOfWar {
    private var revealedTiles: Set<GridPosition> = []
    private var visibleTiles: Set<GridPosition> = []

    let visionRange: Int

    init(visionRange: Int = 6) {
        self.visionRange = visionRange
    }

    /// 根據所有玩家位置更新可見區域
    mutating func update(playerPositions: [GridPosition], map: GameMap) {
        visibleTiles.removeAll()

        for playerPos in playerPositions {
            let visible = calculateVisibility(from: playerPos, map: map)
            visibleTiles.formUnion(visible)
            revealedTiles.formUnion(visible)
        }
    }

    /// 計算從某個位置的可見格子（使用射線投射）
    private func calculateVisibility(from origin: GridPosition, map: GameMap) -> Set<GridPosition> {
        var visible = Set<GridPosition>()
        visible.insert(origin)

        // 向所有方向投射射線
        let steps = 360
        for i in 0..<steps {
            let angle = Double(i) * (2.0 * .pi / Double(steps))
            let dx = cos(angle)
            let dy = sin(angle)

            for distance in 1...visionRange {
                let x = origin.x + Int((dx * Double(distance)).rounded())
                let y = origin.y + Int((dy * Double(distance)).rounded())
                let pos = GridPosition(x: x, y: y)

                guard let tile = map.tile(at: pos) else { break }
                visible.insert(pos)

                // 牆壁阻擋視線
                if tile.terrain == .wall {
                    break
                }
            }
        }

        return visible
    }

    /// 檢查格子是否目前可見
    func isVisible(_ pos: GridPosition) -> Bool {
        visibleTiles.contains(pos)
    }

    /// 檢查格子是否曾被探索
    func isRevealed(_ pos: GridPosition) -> Bool {
        revealedTiles.contains(pos)
    }

    /// 取得格子的可見狀態
    func visibilityState(at pos: GridPosition) -> TileVisibility {
        if visibleTiles.contains(pos) {
            return .visible
        } else if revealedTiles.contains(pos) {
            return .explored
        } else {
            return .hidden
        }
    }

    /// 揭露指定區域（DM 用）
    mutating func reveal(positions: [GridPosition]) {
        for pos in positions {
            revealedTiles.insert(pos)
            visibleTiles.insert(pos)
        }
    }

    /// 隱藏指定區域（DM 用）
    mutating func hide(positions: [GridPosition]) {
        for pos in positions {
            visibleTiles.remove(pos)
        }
    }

    /// 重設所有迷霧
    mutating func reset() {
        revealedTiles.removeAll()
        visibleTiles.removeAll()
    }
}

enum TileVisibility: String {
    case hidden   = "隱藏"      // 完全未探索，顯示黑色
    case explored = "已探索"    // 曾經看過但不在視線內，顯示灰色
    case visible  = "可見"      // 目前在視線內，完全顯示
}
