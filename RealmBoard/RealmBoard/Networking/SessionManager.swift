import Foundation
import MultipeerConnectivity
import Combine

/// 多裝置連線管理器 — 使用 MultipeerConnectivity 實現無網路連線
final class SessionManager: NSObject, ObservableObject {
    static let serviceType = "realmboard-trpg"

    private let myPeerID: MCPeerID
    private var session: MCSession!
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?

    @Published var connectedPeers: [MCPeerID] = []
    @Published var availableRooms: [MCPeerID] = []
    @Published var connectionState: ConnectionState = .disconnected
    @Published var hostName: String = ""

    var onMessageReceived: ((GameMessage) -> Void)?

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    enum ConnectionState: Equatable {
        case disconnected
        case hosting
        case browsing
        case connecting
        case connected
    }

    override init() {
        self.myPeerID = MCPeerID(displayName: UIDevice.current.name)
        super.init()
        self.session = MCSession(
            peer: myPeerID,
            securityIdentity: nil,
            encryptionPreference: .required
        )
        self.session.delegate = self
    }

    // MARK: - 建立房間 (Host)

    func startHosting() {
        stopAll()
        hostName = myPeerID.displayName
        advertiser = MCNearbyServiceAdvertiser(
            peer: myPeerID,
            discoveryInfo: ["role": "host"],
            serviceType: Self.serviceType
        )
        advertiser?.delegate = self
        advertiser?.startAdvertisingPeer()
        connectionState = .hosting
    }

    // MARK: - 搜尋房間 (Browse)

    func startBrowsing() {
        stopAll()
        browser = MCNearbyServiceBrowser(
            peer: myPeerID,
            serviceType: Self.serviceType
        )
        browser?.delegate = self
        browser?.startBrowsingForPeers()
        connectionState = .browsing
    }

    // MARK: - 加入房間

    func joinRoom(host: MCPeerID) {
        guard let browser else { return }
        browser.invitePeer(host, to: session, withContext: nil, timeout: 30)
        connectionState = .connecting
    }

    // MARK: - 停止所有連線

    func stopAll() {
        advertiser?.stopAdvertisingPeer()
        browser?.stopBrowsingForPeers()
        advertiser = nil
        browser = nil
    }

    // MARK: - 發送訊息

    func broadcast(_ message: GameMessage) {
        guard !session.connectedPeers.isEmpty else { return }
        do {
            let data = try encoder.encode(message)
            try session.send(data, toPeers: session.connectedPeers, with: .reliable)
        } catch {
            print("❌ 廣播失敗: \(error)")
        }
    }

    func send(_ message: GameMessage, to peer: MCPeerID) {
        do {
            let data = try encoder.encode(message)
            try session.send(data, toPeers: [peer], with: .reliable)
        } catch {
            print("❌ 傳送失敗: \(error)")
        }
    }

    // MARK: - 斷線

    func disconnect() {
        session.disconnect()
        stopAll()
        connectionState = .disconnected
        connectedPeers = []
    }
}

// MARK: - MCSessionDelegate

extension SessionManager: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async { [weak self] in
            switch state {
            case .connected:
                if !(self?.connectedPeers.contains(peerID) ?? false) {
                    self?.connectedPeers.append(peerID)
                }
                self?.connectionState = .connected
            case .notConnected:
                self?.connectedPeers.removeAll { $0 == peerID }
                if self?.connectedPeers.isEmpty ?? true {
                    self?.connectionState = self?.advertiser != nil ? .hosting : .disconnected
                }
            case .connecting:
                self?.connectionState = .connecting
            @unknown default:
                break
            }
        }
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        do {
            let message = try decoder.decode(GameMessage.self, from: data)
            DispatchQueue.main.async { [weak self] in
                self?.onMessageReceived?(message)
            }
        } catch {
            print("❌ 解碼訊息失敗: \(error)")
        }
    }

    func session(_ session: MCSession, didReceive stream: InputStream, withName: String, fromPeer: MCPeerID) {}
    func session(_ session: MCSession, didStartReceivingResourceWithName: String, fromPeer: MCPeerID, with: Progress) {}
    func session(_ session: MCSession, didFinishReceivingResourceWithName: String, fromPeer: MCPeerID, at: URL?, withError: Error?) {}
}

// MARK: - MCNearbyServiceAdvertiserDelegate

extension SessionManager: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser,
                    didReceiveInvitationFromPeer peerID: MCPeerID,
                    withContext context: Data?,
                    invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        // 自動接受連線
        invitationHandler(true, session)
    }
}

// MARK: - MCNearbyServiceBrowserDelegate

extension SessionManager: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        DispatchQueue.main.async { [weak self] in
            if !(self?.availableRooms.contains(peerID) ?? false) {
                self?.availableRooms.append(peerID)
            }
        }
    }

    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        DispatchQueue.main.async { [weak self] in
            self?.availableRooms.removeAll { $0 == peerID }
        }
    }
}
