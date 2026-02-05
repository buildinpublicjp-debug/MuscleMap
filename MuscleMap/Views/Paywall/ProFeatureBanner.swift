import SwiftUI

// MARK: - Pro機能ロックバナー

struct ProFeatureBanner: View {
    let feature: ProFeature
    let onUpgrade: () -> Void

    var body: some View {
        Button(action: onUpgrade) {
            HStack(spacing: 12) {
                Image(systemName: "lock.fill")
                    .font(.title3)
                    .foregroundStyle(Color.mmOnboardingAccent)

                VStack(alignment: .leading, spacing: 2) {
                    Text(feature.title)
                        .font(.subheadline.bold())
                        .foregroundStyle(Color.mmTextPrimary)
                    Text(L10n.proFeatureLocked)
                        .font(.caption)
                        .foregroundStyle(Color.mmOnboardingAccent)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Color.mmTextSecondary)
            }
            .padding(16)
            .background(Color.mmBgCard)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Pro機能タイプ

@MainActor
enum ProFeature {
    case recovery
    case widget
    case unlimitedHistory
    case export

    var title: String {
        switch self {
        case .recovery: return L10n.proFeatureRecovery
        case .widget: return L10n.proFeatureWidget
        case .unlimitedHistory: return L10n.proFeatureUnlimitedHistory
        case .export: return L10n.proFeatureExport
        }
    }

    var icon: String {
        switch self {
        case .recovery: return "heart.text.clipboard"
        case .widget: return "rectangle.on.rectangle"
        case .unlimitedHistory: return "clock.arrow.circlepath"
        case .export: return "square.and.arrow.up"
        }
    }
}

#Preview {
    ZStack {
        Color.mmBgPrimary.ignoresSafeArea()
        VStack(spacing: 12) {
            ProFeatureBanner(feature: .recovery) {}
            ProFeatureBanner(feature: .unlimitedHistory) {}
        }
        .padding()
    }
}
