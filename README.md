# RealmBoard — 多裝置奇幻桌遊 (Multi-Device Fantasy TRPG)

> 使用多台 iPhone / iPad 拼接成一張大地圖，進行 D&D 風格多人奇幻對戰桌遊。

## 概念

將 2–6 台 Apple 裝置（iPhone & iPad）放在桌面上，透過 **MultipeerConnectivity** 自動偵測鄰近裝置，
各螢幕無縫拼接成一張巨大的奇幻大陸地圖。玩家在自己的手機上操控角色，iPad 可作為 DM（城主）控制台。

```
┌─────────┐ ┌─────────┐ ┌─────────┐
│ iPhone A│ │ iPad DM │ │ iPhone B│
│ 戰士    │ │  地圖   │ │  法師   │
│ (玩家1) │ │ + 控制台│ │ (玩家2) │
└─────────┘ └─────────┘ └─────────┘
     ┌─────────┐ ┌─────────┐
     │ iPhone C│ │ iPhone D│
     │  盜賊   │ │  牧師   │
     │ (玩家3) │ │ (玩家4) │
     └─────────┘ └─────────┘
```

## 核心功能

### 1. 多裝置地圖拼接 (Multi-Device Map Stitching)
- 每台裝置顯示大地圖的一個區塊
- 拖拉 + 陀螺儀輔助自動校正位置
- 裝置靠近時自動偵測並拼接

### 2. D&D 戰鬥系統
- 六大屬性：力量(STR)、敏捷(DEX)、體質(CON)、智力(INT)、感知(WIS)、魅力(CHA)
- d20 骰子判定系統
- 回合制戰鬥（先攻 → 行動 → 結算）
- 職業系統：戰士、法師、盜賊、牧師、遊俠、吟遊詩人

### 3. 角色系統
- 種族：人類、精靈、矮人、半身人、龍裔、提夫林
- 職業技能樹
- 裝備與背包系統
- 等級與經驗值

### 4. 城主 (DM) 模式
- iPad 大螢幕專屬介面
- 即時放置怪物、寶箱、陷阱
- 控制 NPC 對話
- 管理戰爭迷霧 (Fog of War)
- 劇情事件觸發器

### 5. 連線機制
- Apple MultipeerConnectivity (無需 WiFi/網路)
- 自動裝置發現與配對
- 即時遊戲狀態同步
- 斷線重連機制

## 技術架構

```
┌────────────────────────────────────────────┐
│              SwiftUI Views                  │
│  MapView · CharacterSheet · CombatHUD      │
│  DMConsole · DiceRoller · InventoryView     │
├────────────────────────────────────────────┤
│            ViewModels (MVVM)                │
│  GameViewModel · CombatVM · MapVM · DMVM   │
├────────────────────────────────────────────┤
│             Game Engine                     │
│  CombatEngine · DiceEngine · TurnManager   │
│  FogOfWar · MapStitcher · PathFinder       │
├────────────────────────────────────────────┤
│            Networking Layer                 │
│  SessionManager (MultipeerConnectivity)    │
│  MessageRouter · StateSynchronizer         │
├────────────────────────────────────────────┤
│              Data Models                    │
│  Character · Monster · Spell · Item · Tile │
└────────────────────────────────────────────┘
```

## 遊戲流程

1. **建立連線** — 一台裝置建立房間，其他裝置加入
2. **選擇角色** — 每位玩家建立 / 選擇角色（種族、職業、屬性）
3. **地圖拼接** — 將裝置排列在桌面上，自動偵測相對位置
4. **冒險開始** — DM 開始敘述劇情，玩家在地圖上移動
5. **遭遇戰鬥** — 觸發回合制戰鬥，擲骰決定結果
6. **探索與成長** — 獲得經驗、寶物，角色升級

## 系統需求

- iOS 17.0+
- iPhone / iPad
- Swift 5.9+
- SwiftUI
- MultipeerConnectivity Framework

## 專案結構

```
RealmBoard/
├── App/                    # App 入口與設定
├── Models/                 # 資料模型
├── Networking/             # 多裝置連線
├── GameEngine/             # 遊戲邏輯引擎
├── Views/                  # SwiftUI 視圖
├── ViewModels/             # MVVM ViewModel
├── Resources/              # 素材資源
└── Extensions/             # Swift 擴展
```
