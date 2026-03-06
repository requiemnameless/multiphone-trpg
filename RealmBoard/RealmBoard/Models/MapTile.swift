/// 地圖模型 — 定義格子座標、地形類型、地圖格、陷阱與完整遊戲地圖結構
import Foundation

// MARK: - 地圖格座標

struct GridPosition: Codable, Equatable, Hashable {
    var x: Int
    var y: Int

    static let zero = GridPosition(x: 0, y: 0)

    func distance(to other: GridPosition) -> Int {
        max(abs(x - other.x), abs(y - other.y))
    }

    func manhattanDistance(to other: GridPosition) -> Int {
        abs(x - other.x) + abs(y - other.y)
    }

    /// 取得鄰近格子（八方向）
    var neighbors: [GridPosition] {
        [
            GridPosition(x: x-1, y: y-1), GridPosition(x: x, y: y-1), GridPosition(x: x+1, y: y-1),
            GridPosition(x: x-1, y: y),                                GridPosition(x: x+1, y: y),
            GridPosition(x: x-1, y: y+1), GridPosition(x: x, y: y+1), GridPosition(x: x+1, y: y+1),
        ]
    }

    /// 取得鄰近格子（四方向）
    var cardinalNeighbors: [GridPosition] {
        [
            GridPosition(x: x, y: y-1),
            GridPosition(x: x-1, y: y), GridPosition(x: x+1, y: y),
            GridPosition(x: x, y: y+1),
        ]
    }
}

// MARK: - 地形類型

enum TerrainType: String, Codable, CaseIterable {
    case grass      = "草地"
    case stone      = "石板"
    case water      = "水域"
    case lava       = "岩漿"
    case forest     = "樹林"
    case mountain   = "山脈"
    case sand       = "沙地"
    case snow       = "雪地"
    case dungeon    = "地城"
    case wall       = "牆壁"
    case door       = "門"
    case void       = "虛空"

    var isPassable: Bool {
        switch self {
        case .wall, .void, .lava, .mountain:
            return false
        default:
            return true
        }
    }

    var movementCost: Int {
        switch self {
        case .grass, .stone, .dungeon, .door, .sand: return 1
        case .forest, .snow:   return 2
        case .water:           return 3
        case .wall, .void, .lava, .mountain: return Int.max
        }
    }

    var symbol: String {
        switch self {
        case .grass:    return "🌿"
        case .stone:    return "🪨"
        case .water:    return "💧"
        case .lava:     return "🌋"
        case .forest:   return "🌲"
        case .mountain: return "⛰️"
        case .sand:     return "🏜️"
        case .snow:     return "❄️"
        case .dungeon:  return "🏚️"
        case .wall:     return "🧱"
        case .door:     return "🚪"
        case .void:     return "⬛"
        }
    }
}

// MARK: - 地圖格

struct MapTile: Codable, Identifiable, Equatable {
    let id: UUID
    var position: GridPosition
    var terrain: TerrainType
    var isRevealed: Bool        // 戰爭迷霧
    var isLit: Bool             // 光源照亮
    var occupant: TileOccupant?
    var trapType: TrapType?
    var lootItems: [Item]

    var isPassable: Bool {
        terrain.isPassable && occupant == nil
    }

    static func create(_ terrain: TerrainType, at position: GridPosition) -> MapTile {
        MapTile(
            id: UUID(),
            position: position,
            terrain: terrain,
            isRevealed: false,
            isLit: false,
            occupant: nil,
            trapType: nil,
            lootItems: []
        )
    }
}

// MARK: - 格子佔領物

enum TileOccupant: Codable, Equatable {
    case player(UUID)       // 玩家角色 ID
    case monster(UUID)      // 怪物 ID
    case npc(String)        // NPC 名稱
    case chest              // 寶箱
    case interactable(String) // 可互動物件
}

// MARK: - 陷阱

enum TrapType: String, Codable {
    case pitTrap     = "陷坑"
    case poisonDart  = "毒鏢"
    case fireTrap    = "火焰陷阱"
    case alarmTrap   = "警報陷阱"
    case magicRune   = "魔法符文"

    var damage: String {
        switch self {
        case .pitTrap:    return "1d6"
        case .poisonDart: return "1d4"
        case .fireTrap:   return "2d6"
        case .alarmTrap:  return "0"
        case .magicRune:  return "3d6"
        }
    }

    var detectionDC: Int {
        switch self {
        case .pitTrap:    return 10
        case .poisonDart: return 13
        case .fireTrap:   return 15
        case .alarmTrap:  return 12
        case .magicRune:  return 17
        }
    }
}

// MARK: - 遊戲地圖

struct GameMap: Codable, Equatable {
    var width: Int
    var height: Int
    var tiles: [[MapTile]]
    var name: String

    /// 建立空地圖
    static func empty(width: Int, height: Int, terrain: TerrainType = .grass, name: String = "未命名地圖") -> GameMap {
        let tiles = (0..<height).map { y in
            (0..<width).map { x in
                MapTile.create(terrain, at: GridPosition(x: x, y: y))
            }
        }
        return GameMap(width: width, height: height, tiles: tiles, name: name)
    }

    /// 取得特定位置的 tile
    func tile(at pos: GridPosition) -> MapTile? {
        guard pos.x >= 0, pos.x < width, pos.y >= 0, pos.y < height else { return nil }
        return tiles[pos.y][pos.x]
    }

    /// 修改特定位置的 tile
    mutating func setTile(_ tile: MapTile, at pos: GridPosition) {
        guard pos.x >= 0, pos.x < width, pos.y >= 0, pos.y < height else { return }
        tiles[pos.y][pos.x] = tile
    }

    /// 建立地城範本地圖
    static func sampleDungeon() -> GameMap {
        var map = GameMap.empty(width: 20, height: 15, terrain: .void, name: "幽暗地城")

        // 建立房間
        for y in 1...5 {
            for x in 1...7 {
                map.tiles[y][x] = .create(.dungeon, at: GridPosition(x: x, y: y))
            }
        }

        // 走廊
        for x in 8...12 {
            map.tiles[3][x] = .create(.stone, at: GridPosition(x: x, y: 3))
        }

        // 第二個房間
        for y in 1...5 {
            for x in 13...18 {
                map.tiles[y][x] = .create(.dungeon, at: GridPosition(x: x, y: y))
            }
        }

        // 南方走廊
        for y in 6...9 {
            map.tiles[y][4] = .create(.stone, at: GridPosition(x: 4, y: y))
        }

        // Boss 房間
        for y in 10...13 {
            for x in 1...7 {
                map.tiles[y][x] = .create(.stone, at: GridPosition(x: x, y: y))
            }
        }

        // 門
        map.tiles[3][8] = .create(.door, at: GridPosition(x: 8, y: 3))
        map.tiles[6][4] = .create(.door, at: GridPosition(x: 4, y: 6))
        map.tiles[10][4] = .create(.door, at: GridPosition(x: 4, y: 10))

        return map
    }
}
