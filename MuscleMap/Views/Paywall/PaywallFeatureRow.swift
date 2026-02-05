import SwiftUI

// MARK: - Paywall特典行

struct PaywallFeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "checkmark.circle.fill")
                .font(.title3)
                .foregroundStyle(Color.mmOnboardingAccent)

            Text(text)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Color.mmOnboardingTextMain)
        }
    }
}

#Preview {
    ZStack {
        Color.mmOnboardingBg.ignoresSafeArea()
        VStack(alignment: .leading, spacing: 16) {
            PaywallFeatureRow(icon: "heart.text.clipboard", text: "EMGベースの回復予測")
            PaywallFeatureRow(icon: "rectangle.on.rectangle", text: "ホームスクリーンウィジェット")
            PaywallFeatureRow(icon: "clock.arrow.circlepath", text: "無制限の履歴閲覧")
            PaywallFeatureRow(icon: "square.and.arrow.up", text: "データエクスポート（CSV）")
        }
        .padding()
    }
}
