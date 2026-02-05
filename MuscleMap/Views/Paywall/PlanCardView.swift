import SwiftUI

// MARK: - プランカード（縦型）

struct PlanCardView: View {
    let title: String
    let price: String
    let subtitle: String?
    let badge: String?
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                // バッジ
                if let badge {
                    Text(badge)
                        .font(.caption2.bold())
                        .foregroundStyle(Color.mmOnboardingBg)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.mmOnboardingAccent)
                        .clipShape(Capsule())
                } else {
                    // バッジ分のスペース確保
                    Text(" ")
                        .font(.caption2.bold())
                        .padding(.vertical, 3)
                        .opacity(0)
                }

                // プラン名
                Text(title)
                    .font(.caption.bold())
                    .foregroundStyle(Color.mmOnboardingTextSub)

                // 価格
                Text(price)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color.mmOnboardingTextMain)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)

                // サブテキスト
                if let subtitle {
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundStyle(Color.mmOnboardingAccent)
                } else {
                    Text(" ")
                        .font(.caption2)
                        .opacity(0)
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.mmOnboardingAccent.opacity(0.08) : Color.mmOnboardingCard)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isSelected ? Color.mmOnboardingAccent : Color.mmOnboardingCard,
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ZStack {
        Color.mmOnboardingBg.ignoresSafeArea()
        HStack(spacing: 10) {
            PlanCardView(title: "月額", price: "¥480", subtitle: nil, badge: nil, isSelected: false) {}
            PlanCardView(title: "年額", price: "¥3,800", subtitle: "~¥317/月", badge: "一番人気", isSelected: true) {}
            PlanCardView(title: "買い切り", price: "¥7,800", subtitle: "生涯アクセス", badge: nil, isSelected: false) {}
        }
        .padding()
    }
}
