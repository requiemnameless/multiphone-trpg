import SwiftUI

/// 地圖拼接設定畫面 — 讓玩家配置各裝置在桌面上的相對位置
struct MapSetupView: View {
    @EnvironmentObject var coordinator: GameCoordinator
    @State private var gridRows = 2
    @State private var gridCols = 3
    @State private var selectedSlot: (Int, Int)?
    @State private var isReady = false

    private var totalDevices: Int {
        coordinator.sessionManager.connectedPeers.count + 1  // +1 for self
    }

    var body: some View {
        ZStack {
            Color(hex: "1a1a2e").ignoresSafeArea()

            VStack(spacing: 24) {
                // 標題
                VStack(spacing: 8) {
                    Text("地圖拼接設定")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Text("將你的裝置放在桌面上，然後點選對應的位置")
                        .font(.subheadline)
                        .foregroundColor(.gray)

                    Text("\(totalDevices) 台裝置已連線")
                        .font(.caption)
                        .foregroundColor(.blue)
                }

                // 佈局控制
                HStack(spacing: 20) {
                    VStack {
                        Text("列數")
                            .foregroundColor(.gray)
                        Stepper("\(gridRows)", value: $gridRows, in: 1...4)
                            .frame(width: 120)
                    }
                    VStack {
                        Text("行數")
                            .foregroundColor(.gray)
                        Stepper("\(gridCols)", value: $gridCols, in: 1...4)
                            .frame(width: 120)
                    }
                }
                .foregroundColor(.white)

                // 裝置佈局網格
                deviceGrid

                // 連線裝置列表
                connectedDevicesList

                Spacer()

                // 說明圖
                instructionView

                // 開始按鈕
                Button {
                    setupMap()
                } label: {
                    HStack {
                        Image(systemName: "map.fill")
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
                .padding(.horizontal, 40)
            }
            .padding()
        }
    }

    // MARK: - 裝置佈局網格

    private var deviceGrid: some View {
        VStack(spacing: 4) {
            ForEach(0..<gridRows, id: \.self) { row in
                HStack(spacing: 4) {
                    ForEach(0..<gridCols, id: \.self) { col in
                        deviceSlot(row: row, col: col)
                    }
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }

    private func deviceSlot(row: Int, col: Int) -> some View {
        let isSelected = selectedSlot?.0 == row && selectedSlot?.1 == col
        let region = coordinator.mapStitcher.deviceRegions.first {
            $0.physicalPosition.row == row && $0.physicalPosition.col == col
        }

        return Button {
            selectedSlot = (row, col)
        } label: {
            VStack(spacing: 4) {
                if let region {
                    Image(systemName: "iphone")
                        .font(.title2)
                    Text(region.deviceName)
                        .font(.caption2)
                        .lineLimit(1)
                } else {
                    Image(systemName: "plus.rectangle.on.rectangle")
                        .font(.title2)
                        .foregroundColor(.gray)
                    Text("空位")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
            .frame(width: 80, height: 80)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.blue.opacity(0.3) : Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .foregroundColor(.white)
    }

    // MARK: - 連線裝置列表

    private var connectedDevicesList: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("已連線裝置")
                .font(.headline)
                .foregroundColor(.white)

            HStack {
                Image(systemName: "iphone")
                    .foregroundColor(.green)
                Text("本機")
                    .foregroundColor(.white)
                Text("(你)")
                    .foregroundColor(.gray)
            }

            ForEach(coordinator.sessionManager.connectedPeers, id: \.displayName) { peer in
                HStack {
                    Image(systemName: "iphone")
                        .foregroundColor(.blue)
                    Text(peer.displayName)
                        .foregroundColor(.white)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }

    // MARK: - 說明

    private var instructionView: some View {
        VStack(spacing: 8) {
            Text("使用方式")
                .font(.headline)
                .foregroundColor(.white)

            Text("""
            1. 將所有裝置排列在桌面上
            2. 點選網格中對應的位置放置裝置
            3. 確認佈局後開始冒險
            """)
            .font(.caption)
            .foregroundColor(.gray)
            .multilineTextAlignment(.leading)
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }

    // MARK: - 設定地圖

    private func setupMap() {
        coordinator.mapStitcher.autoAssignRegions(
            deviceCount: totalDevices,
            mapSize: GridSize(width: 20, height: 15)
        )
        coordinator.advancePhase()
    }
}
