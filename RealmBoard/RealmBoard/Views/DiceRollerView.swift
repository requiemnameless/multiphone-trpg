import SwiftUI

/// 骰子擲骰介面
struct DiceRollerView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedDie: DieType = .d20
    @State private var diceCount = 1
    @State private var modifier = 0
    @State private var results: [DiceResult] = []
    @State private var isRolling = false

    private let diceTypes: [(DieType, String)] = [
        (.d4, "d4"), (.d6, "d6"), (.d8, "d8"),
        (.d10, "d10"), (.d12, "d12"), (.d20, "d20"), (.d100, "d100"),
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "1a1a2e").ignoresSafeArea()

                VStack(spacing: 24) {
                    // 骰子選擇
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(diceTypes, id: \.1) { die, label in
                                Button {
                                    selectedDie = die
                                } label: {
                                    VStack {
                                        dieIcon(die)
                                            .font(.system(size: 36))
                                        Text(label)
                                            .font(.caption)
                                    }
                                    .foregroundColor(selectedDie == die ? .yellow : .white)
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(selectedDie == die ? Color.yellow.opacity(0.2) : Color.white.opacity(0.05))
                                    )
                                }
                            }
                        }
                        .padding(.horizontal)
                    }

                    // 骰數 & 修正值
                    HStack(spacing: 30) {
                        VStack {
                            Text("骰數")
                                .font(.caption)
                                .foregroundColor(.gray)
                            HStack {
                                Button { diceCount = max(1, diceCount - 1) } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.red)
                                }
                                Text("\(diceCount)")
                                    .font(.title)
                                    .foregroundColor(.white)
                                    .frame(width: 40)
                                Button { diceCount = min(20, diceCount + 1) } label: {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.green)
                                }
                            }
                        }

                        VStack {
                            Text("修正值")
                                .font(.caption)
                                .foregroundColor(.gray)
                            HStack {
                                Button { modifier -= 1 } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.red)
                                }
                                Text(modifier >= 0 ? "+\(modifier)" : "\(modifier)")
                                    .font(.title)
                                    .foregroundColor(.white)
                                    .frame(width: 50)
                                Button { modifier += 1 } label: {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.green)
                                }
                            }
                        }
                    }

                    // 擲骰公式
                    Text("\(diceCount)\(selectedDie.displayName)\(modifier >= 0 ? "+\(modifier)" : "\(modifier)")")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.yellow)

                    // 擲骰按鈕
                    Button {
                        rollDice()
                    } label: {
                        HStack {
                            Image(systemName: "dice.fill")
                            Text("擲骰！")
                        }
                        .font(.title2)
                        .fontWeight(.bold)
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
                        .cornerRadius(20)
                        .scaleEffect(isRolling ? 0.95 : 1)
                    }
                    .padding(.horizontal, 40)

                    // 結果
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(results) { result in
                                resultCard(result)
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("擲骰")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("關閉") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("清除") { results.removeAll() }
                }
            }
        }
    }

    // MARK: - 擲骰

    private func rollDice() {
        withAnimation(.spring(response: 0.3)) {
            isRolling = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            let result = DiceEngine.roll(diceCount, selectedDie, modifier: modifier, purpose: "手動擲骰")
            results.insert(result, at: 0)
            withAnimation {
                isRolling = false
            }
        }
    }

    // MARK: - 結果卡片

    private func resultCard(_ result: DiceResult) -> some View {
        VStack(spacing: 8) {
            HStack {
                Text("\(result.count)\(result.dieType.displayName)")
                    .font(.caption)
                    .foregroundColor(.gray)
                Spacer()

                if result.isCriticalHit {
                    Text("爆擊！")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.yellow)
                        .padding(.horizontal, 8)
                        .background(Color.yellow.opacity(0.2))
                        .cornerRadius(8)
                }
                if result.isCriticalMiss {
                    Text("大失敗！")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                        .padding(.horizontal, 8)
                        .background(Color.red.opacity(0.2))
                        .cornerRadius(8)
                }
            }

            // 個別骰子結果
            HStack {
                ForEach(result.rolls.indices, id: \.self) { i in
                    Text("\(result.rolls[i])")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                }
                if result.modifier != 0 {
                    Text(result.modifier >= 0 ? "+\(result.modifier)" : "\(result.modifier)")
                        .font(.headline)
                        .foregroundColor(.orange)
                }
            }

            // 總計
            Text("= \(result.total)")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(result.isCriticalHit ? .yellow : .white)
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
        .padding(.horizontal)
    }

    private func dieIcon(_ die: DieType) -> some View {
        Image(systemName: "die.face.\(min(die.sides, 6)).fill")
    }
}
