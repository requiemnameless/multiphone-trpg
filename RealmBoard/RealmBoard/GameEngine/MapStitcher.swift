/// 多裝置地圖拼接引擎 — 將多台 iPhone/iPad 螢幕無縫拼接成一張大地圖
import Foundation
import CoreMotion
import Combine

/// 裝置在大地圖中的區域分配
struct DeviceMapRegion: Codable, Equatable, Identifiable {
    let id: UUID
    let deviceName: String
    var gridOrigin: GridPosition      // 該裝置負責顯示的地圖左上角
    var gridSize: GridSize            // 該裝置顯示的格數 (寬 x 高)
    var physicalPosition: PhysicalPos // 實際桌面上的相對位置
    var screenResolution: ScreenSize
}

struct GridSize: Codable, Equatable {
    var width: Int
    var height: Int
}

struct ScreenSize: Codable, Equatable {
    var width: Double
    var height: Double
}

struct PhysicalPos: Codable, Equatable {
    var row: Int    // 在桌面上的行（上下）
    var col: Int    // 在桌面上的列（左右）
}

/// 多裝置地圖拼接引擎
///
/// 核心概念：
/// 1. 一台裝置作為 Host，持有完整的大地圖
/// 2. 每台裝置只渲染自己負責的區域
/// 3. 透過手動配置或自動偵測確定各裝置的相對位置
/// 4. 角色跨越螢幕邊界時無縫過渡
@MainActor
final class MapStitcher: ObservableObject {
    @Published var deviceRegions: [DeviceMapRegion] = []
    @Published var localRegion: DeviceMapRegion?
    @Published var totalGridSize: GridSize = GridSize(width: 20, height: 15)
    @Published var layoutGrid: [[UUID?]] = []  // 裝置佈局網格

    private let motionManager = CMMotionManager()

    /// 根據裝置數量自動分配地圖區域
    func autoAssignRegions(deviceCount: Int, mapSize: GridSize) {
        totalGridSize = mapSize
        deviceRegions.removeAll()

        // 計算最佳的行列排列
        let layout = calculateOptimalLayout(deviceCount: deviceCount)
        let colWidth = mapSize.width / layout.cols
        let rowHeight = mapSize.height / layout.rows

        var index = 0
        for row in 0..<layout.rows {
            for col in 0..<layout.cols {
                guard index < deviceCount else { break }

                let region = DeviceMapRegion(
                    id: UUID(),
                    deviceName: "裝置 \(index + 1)",
                    gridOrigin: GridPosition(x: col * colWidth, y: row * rowHeight),
                    gridSize: GridSize(width: colWidth, height: rowHeight),
                    physicalPosition: PhysicalPos(row: row, col: col),
                    screenResolution: ScreenSize(width: 390, height: 844)
                )
                deviceRegions.append(region)
                index += 1
            }
        }

        updateLayoutGrid(rows: layout.rows, cols: layout.cols)
    }

    /// 計算最佳佈局 (盡量接近正方形)
    private func calculateOptimalLayout(deviceCount: Int) -> (rows: Int, cols: Int) {
        let sqrt = Int(Double(deviceCount).squareRoot().rounded(.up))
        let cols = sqrt
        let rows = (deviceCount + cols - 1) / cols
        return (rows, cols)
    }

    /// 手動設定裝置位置
    func setDevicePosition(deviceId: UUID, row: Int, col: Int) {
        guard let index = deviceRegions.firstIndex(where: { $0.id == deviceId }) else { return }
        deviceRegions[index].physicalPosition = PhysicalPos(row: row, col: col)
        recalculateGridOrigins()
    }

    /// 根據實體位置重新計算地圖起始座標
    private func recalculateGridOrigins() {
        let sorted = deviceRegions.sorted {
            if $0.physicalPosition.row != $1.physicalPosition.row {
                return $0.physicalPosition.row < $1.physicalPosition.row
            }
            return $0.physicalPosition.col < $1.physicalPosition.col
        }

        // 找出最大行列
        let maxRow = sorted.map(\.physicalPosition.row).max() ?? 0
        let maxCol = sorted.map(\.physicalPosition.col).max() ?? 0
        let colWidth = totalGridSize.width / (maxCol + 1)
        let rowHeight = totalGridSize.height / (maxRow + 1)

        for i in deviceRegions.indices {
            let pos = deviceRegions[i].physicalPosition
            deviceRegions[i].gridOrigin = GridPosition(x: pos.col * colWidth, y: pos.row * rowHeight)
            deviceRegions[i].gridSize = GridSize(width: colWidth, height: rowHeight)
        }
    }

    /// 更新佈局網格
    private func updateLayoutGrid(rows: Int, cols: Int) {
        layoutGrid = Array(repeating: Array(repeating: nil as UUID?, count: cols), count: rows)
        for region in deviceRegions {
            let r = region.physicalPosition.row
            let c = region.physicalPosition.col
            if r < rows && c < cols {
                layoutGrid[r][c] = region.id
            }
        }
    }

    /// 檢查座標是否在本裝置的顯示區域內
    func isPositionInLocalRegion(_ pos: GridPosition) -> Bool {
        guard let region = localRegion else { return false }
        let origin = region.gridOrigin
        let size = region.gridSize
        return pos.x >= origin.x && pos.x < origin.x + size.width
            && pos.y >= origin.y && pos.y < origin.y + size.height
    }

    /// 將全域地圖座標轉換為本裝置的本地座標
    func globalToLocal(_ pos: GridPosition) -> GridPosition? {
        guard let region = localRegion else { return nil }
        let localX = pos.x - region.gridOrigin.x
        let localY = pos.y - region.gridOrigin.y
        guard localX >= 0, localX < region.gridSize.width,
              localY >= 0, localY < region.gridSize.height else { return nil }
        return GridPosition(x: localX, y: localY)
    }

    /// 將本地座標轉換為全域地圖座標
    func localToGlobal(_ pos: GridPosition) -> GridPosition {
        guard let region = localRegion else { return pos }
        return GridPosition(
            x: pos.x + region.gridOrigin.x,
            y: pos.y + region.gridOrigin.y
        )
    }

    /// 處理來自其他裝置的地圖更新
    func applyRemoteUpdate(_ data: MapUpdateData) {
        // 在實際實作中，這裡會更新本地地圖狀態
        // 包括新揭露的格子、新出現的怪物等
    }

    /// 取得鄰近裝置（用於角色跨螢幕移動）
    func neighborDevice(direction: Direction) -> DeviceMapRegion? {
        guard let local = localRegion else { return nil }
        let pos = local.physicalPosition

        let targetPos: PhysicalPos
        switch direction {
        case .north: targetPos = PhysicalPos(row: pos.row - 1, col: pos.col)
        case .south: targetPos = PhysicalPos(row: pos.row + 1, col: pos.col)
        case .east:  targetPos = PhysicalPos(row: pos.row, col: pos.col + 1)
        case .west:  targetPos = PhysicalPos(row: pos.row, col: pos.col - 1)
        }

        return deviceRegions.first { $0.physicalPosition == targetPos }
    }
}

enum Direction: String, Codable {
    case north, south, east, west
}
