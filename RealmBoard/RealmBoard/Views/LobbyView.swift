import SwiftUI

/// 大廳畫面 — 建立或加入遊戲房間
struct LobbyView: View {
    @EnvironmentObject var coordinator: GameCoordinator
    @State private var playerName = ""
    @State private var showingRoomList = false

    var body: some View {
        NavigationStack {
            ZStack {
                // 背景
                LinearGradient(
                    colors: [Color(hex: "1a1a2e"), Color(hex: "16213e"), Color(hex: "0f3460")],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 30) {
                    // Logo
                    VStack(spacing: 8) {
                        Text("RealmBoard")
                            .font(.system(size: 48, weight: .bold, design: .serif))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.yellow, .orange],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )

                        Text("多裝置奇幻桌遊")
                            .font(.title3)
                            .foregroundColor(.gray)

                        Text("D&D 風格 · 多人對戰 · 即時地圖拼接")
                            .font(.caption)
                            .foregroundColor(.gray.opacity(0.7))
                    }
                    .padding(.top, 60)

                    Spacer()

                    // 玩家名稱
                    VStack(alignment: .leading, spacing: 8) {
                        Text("冒險者名稱")
                            .font(.headline)
                            .foregroundColor(.white)

                        TextField("輸入你的名字...", text: $playerName)
                            .textFieldStyle(.plain)
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(12)
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 40)

                    // 按鈕
                    VStack(spacing: 16) {
                        // 建立房間（DM）
                        Button {
                            coordinator.hostGame(asRole: .dungeonMaster)
                            coordinator.advancePhase()
                        } label: {
                            HStack {
                                Image(systemName: "crown.fill")
                                Text("建立冒險 (城主 DM)")
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

                        // 建立房間（玩家）
                        Button {
                            coordinator.hostGame(asRole: .player)
                            coordinator.advancePhase()
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("建立房間 (玩家)")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue.opacity(0.6))
                            .cornerRadius(16)
                        }

                        // 加入房間
                        Button {
                            coordinator.joinGame()
                            showingRoomList = true
                        } label: {
                            HStack {
                                Image(systemName: "antenna.radiowaves.left.and.right")
                                Text("搜尋並加入房間")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.purple.opacity(0.6))
                            .cornerRadius(16)
                        }
                    }
                    .padding(.horizontal, 40)
                    .disabled(playerName.isEmpty)
                    .opacity(playerName.isEmpty ? 0.5 : 1)

                    Spacer()

                    // 連線狀態
                    HStack {
                        Circle()
                            .fill(coordinator.isConnected ? Color.green : Color.red)
                            .frame(width: 8, height: 8)
                        Text(coordinator.isConnected ? "已連線" : "未連線")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text("·")
                            .foregroundColor(.gray)
                        Text("\(coordinator.sessionManager.connectedPeers.count) 位玩家")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.bottom, 30)
                }
            }
            .sheet(isPresented: $showingRoomList) {
                RoomListView()
            }
        }
    }
}

/// 房間列表
struct RoomListView: View {
    @EnvironmentObject var coordinator: GameCoordinator
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            List {
                if coordinator.sessionManager.availableRooms.isEmpty {
                    VStack(spacing: 12) {
                        ProgressView()
                        Text("正在搜尋附近的房間...")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                } else {
                    ForEach(coordinator.sessionManager.availableRooms, id: \.displayName) { peer in
                        Button {
                            coordinator.sessionManager.joinRoom(host: peer)
                            dismiss()
                            coordinator.advancePhase()
                        } label: {
                            HStack {
                                Image(systemName: "gamecontroller.fill")
                                    .foregroundColor(.purple)
                                Text(peer.displayName)
                                    .font(.headline)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 8)
                        }
                    }
                }
            }
            .navigationTitle("可用房間")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("關閉") { dismiss() }
                }
            }
        }
    }
}
