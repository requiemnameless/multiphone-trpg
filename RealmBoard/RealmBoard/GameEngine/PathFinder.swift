import Foundation

/// A* 尋路演算法 — 計算角色在地圖上的最佳移動路徑
struct PathFinder {
    /// 尋找從起點到終點的最短路徑
    static func findPath(
        from start: GridPosition,
        to end: GridPosition,
        map: GameMap,
        maxDistance: Int = Int.max
    ) -> [GridPosition]? {
        guard let endTile = map.tile(at: end), endTile.isPassable else { return nil }

        var openSet = Set<GridPosition>()
        openSet.insert(start)

        var cameFrom: [GridPosition: GridPosition] = [:]
        var gScore: [GridPosition: Int] = [start: 0]
        var fScore: [GridPosition: Int] = [start: heuristic(start, end)]

        while !openSet.isEmpty {
            // 取 fScore 最小的節點
            guard let current = openSet.min(by: { (fScore[$0] ?? Int.max) < (fScore[$1] ?? Int.max) }) else { break }

            if current == end {
                return reconstructPath(cameFrom: cameFrom, current: current)
            }

            openSet.remove(current)

            for neighbor in current.cardinalNeighbors {
                guard let tile = map.tile(at: neighbor), tile.isPassable else { continue }

                let tentativeG = (gScore[current] ?? Int.max) + tile.terrain.movementCost

                if tentativeG > maxDistance { continue }

                if tentativeG < (gScore[neighbor] ?? Int.max) {
                    cameFrom[neighbor] = current
                    gScore[neighbor] = tentativeG
                    fScore[neighbor] = tentativeG + heuristic(neighbor, end)
                    openSet.insert(neighbor)
                }
            }
        }

        return nil // 無法到達
    }

    /// 取得可移動範圍內的所有格子
    static func reachableTiles(
        from start: GridPosition,
        maxDistance: Int,
        map: GameMap
    ) -> Set<GridPosition> {
        var reachable = Set<GridPosition>()
        var visited = Set<GridPosition>()
        var queue: [(position: GridPosition, cost: Int)] = [(start, 0)]

        while !queue.isEmpty {
            let (current, cost) = queue.removeFirst()

            guard !visited.contains(current) else { continue }
            visited.insert(current)

            if cost <= maxDistance {
                reachable.insert(current)
            }

            for neighbor in current.cardinalNeighbors {
                guard !visited.contains(neighbor),
                      let tile = map.tile(at: neighbor),
                      tile.isPassable else { continue }

                let newCost = cost + tile.terrain.movementCost
                if newCost <= maxDistance {
                    queue.append((neighbor, newCost))
                }
            }
        }

        return reachable
    }

    // MARK: - Private

    private static func heuristic(_ a: GridPosition, _ b: GridPosition) -> Int {
        a.manhattanDistance(to: b)
    }

    private static func reconstructPath(
        cameFrom: [GridPosition: GridPosition],
        current: GridPosition
    ) -> [GridPosition] {
        var path = [current]
        var node = current
        while let prev = cameFrom[node] {
            path.insert(prev, at: 0)
            node = prev
        }
        return path
    }
}
