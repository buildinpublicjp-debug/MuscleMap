import SwiftUI

// MARK: - シェアカードヘッダー（統一デザイン）

struct ShareCardHeader: View {
    let title: String
    let subtitle: String?
    let accentColor: Color
    let date: Date

    init(title: String, subtitle: String? = nil, accentColor: Color = .mmAccentPrimary, date: Date = Date()) {
        self.title = title
        self.subtitle = subtitle
        self.accentColor = accentColor
        self.date = date
    }

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter.string(from: date)
    }

    var body: some View {
        VStack(spacing: 8) {
            // 上部: MuscleMap + 日付
            HStack {
                Text("MuscleMap")
                    .font(.system(size: 14, weight: .bold, design: .default))
                    .foregroundStyle(Color.mmTextPrimary)
                Spacer()
                Text(dateString)
                    .font(.caption)
                    .foregroundStyle(Color.mmTextSecondary)
            }
            .padding(.horizontal, 24)

            // タイトル・サブタイトル
            VStack(spacing: 4) {
                Text(title)
                    .font(.caption.bold())
                    .foregroundStyle(accentColor)
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.title3.bold())
                        .foregroundStyle(Color.mmTextPrimary)
                }
            }
        }
        .padding(.top, 16)
    }
}

// MARK: - シェアカードフッター（シンプル）

struct ShareCardFooter: View {
    let accentColor: Color

    init(accentColor: Color = .mmAccentPrimary) {
        self.accentColor = accentColor
    }

    var body: some View {
        VStack(spacing: 12) {
            Rectangle()
                .fill(accentColor.opacity(0.3))
                .frame(height: 1)
                .padding(.horizontal, 24)

            Text("MuscleMap")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.mmTextSecondary.opacity(0.6))
                .padding(.bottom, 16)
        }
    }
}

// MARK: - シェアカードコンテナ

struct ShareCardContainer<Content: View>: View {
    let width: CGFloat
    let height: CGFloat
    let accentColor: Color
    let secondaryColor: Color?
    let backgroundStyle: BackgroundStyle
    let header: ShareCardHeader
    @ViewBuilder let content: () -> Content

    enum BackgroundStyle {
        case solid(Color)
        case gradient([Color])
    }

    init(
        width: CGFloat = 390,
        height: CGFloat = 693,
        accentColor: Color = .mmAccentPrimary,
        secondaryColor: Color? = nil,
        backgroundStyle: BackgroundStyle = .solid(.mmBgCard),
        header: ShareCardHeader,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.width = width
        self.height = height
        self.accentColor = accentColor
        self.secondaryColor = secondaryColor
        self.backgroundStyle = backgroundStyle
        self.header = header
        self.content = content
    }

    var body: some View {
        VStack(spacing: 0) {
            // 上部グラデーションライン
            LinearGradient(
                colors: [accentColor, secondaryColor ?? accentColor.opacity(0.5)],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(height: 4)

            VStack(spacing: 16) {
                // ヘッダー
                header

                // コンテンツ
                content()

                Spacer()

                // フッター
                ShareCardFooter(accentColor: accentColor)
            }
        }
        .frame(width: width, height: height)
        .background(backgroundView)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay {
            RoundedRectangle(cornerRadius: 24)
                .stroke(accentColor.opacity(0.3), lineWidth: 2)
        }
        .padding(8)
        .background(Color.mmBgPrimary)
    }

    @ViewBuilder
    private var backgroundView: some View {
        switch backgroundStyle {
        case .solid(let color):
            color
        case .gradient(let colors):
            LinearGradient(
                colors: colors,
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
}

// MARK: - シェアカード統計アイテム

struct ShareCardStatItem: View {
    let value: String
    let unit: String?
    let label: String

    init(_ value: String, unit: String? = nil, label: String) {
        self.value = value
        self.unit = unit
        self.label = label
    }

    var body: some View {
        VStack(spacing: 2) {
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title2.bold())
                    .foregroundStyle(Color.mmAccentPrimary)
                if let unit = unit {
                    Text(unit)
                        .font(.caption)
                        .foregroundStyle(Color.mmTextSecondary)
                }
            }
            Text(label)
                .font(.caption2)
                .foregroundStyle(Color.mmTextSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview

#Preview {
    ShareCardContainer(
        header: ShareCardHeader(title: "SAMPLE CARD", subtitle: "Sample Subtitle")
    ) {
        VStack {
            Text("Content goes here")
                .foregroundStyle(Color.mmTextPrimary)

            HStack {
                ShareCardStatItem("42", unit: nil, label: "Sets")
                ShareCardStatItem("1.2k", unit: "kg", label: "Volume")
            }
        }
    }
}
