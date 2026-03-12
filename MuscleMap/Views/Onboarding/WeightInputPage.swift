import SwiftUI

// MARK: - 体重・ニックネーム入力画面

struct WeightInputPage: View {
    let onNext: () -> Void

    @State private var selectedWeightKg: Int = Int(AppState.shared.userProfile.weightKg)
    @State private var nickname: String = AppState.shared.userProfile.nickname
    @State private var selectedUnit: WeightUnit = AppState.shared.weightUnit
    @State private var isProceeding = false
    @State private var appeared = false

    /// Picker用の体重レンジ（kg）
    private let weightRangeKg = Array(40...160)

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 60)

            // タイトルエリア
            VStack(spacing: 8) {
                Text(L10n.weightInputTitle)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(Color.mmOnboardingTextMain)
                    .multilineTextAlignment(.center)

                Text(L10n.weightInputSubtitle)
                    .font(.subheadline)
                    .foregroundStyle(Color.mmOnboardingTextSub)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)

            Spacer().frame(height: 32)

            // カード: ニックネーム入力
            VStack(spacing: 16) {
                TextField(L10n.nicknamePlaceholder, text: $nickname)
                    .font(.system(size: 18))
                    .foregroundStyle(Color.mmOnboardingTextMain)
                    .padding(16)
                    .background(Color.mmOnboardingBg.opacity(0.6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .onChange(of: nickname) { _, newValue in
                        AppState.shared.userProfile.nickname = newValue
                    }
            }
            .padding(16)
            .background(Color.mmOnboardingCard)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 24)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)

            Spacer().frame(height: 16)

            // カード: 体重Picker + kg/lbトグル
            VStack(spacing: 16) {
                // kg/lb トグル
                HStack(spacing: 0) {
                    ForEach(WeightUnit.allCases, id: \.rawValue) { unit in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedUnit = unit
                                AppState.shared.weightUnit = unit
                            }
                            HapticManager.lightTap()
                        } label: {
                            Text(unit.displayName)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(
                                    selectedUnit == unit
                                        ? Color.mmOnboardingBg
                                        : Color.mmOnboardingTextSub
                                )
                                .frame(maxWidth: .infinity)
                                .frame(height: 40)
                                .background(
                                    selectedUnit == unit
                                        ? Color.mmOnboardingAccent
                                        : Color.clear
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(4)
                .background(Color.mmOnboardingBg.opacity(0.6))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // ドラムロールPicker
                Picker("", selection: $selectedWeightKg) {
                    ForEach(weightRangeKg, id: \.self) { kg in
                        Text(pickerLabel(forKg: kg))
                            .tag(kg)
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 150)
                .onChange(of: selectedWeightKg) { _, newValue in
                    AppState.shared.userProfile.weightKg = Double(newValue)
                }
            }
            .padding(16)
            .background(Color.mmOnboardingCard)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 24)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)

            Spacer()

            // 次へボタン
            Button {
                guard !isProceeding else { return }
                isProceeding = true
                HapticManager.lightTap()
                onNext()
            } label: {
                Text(L10n.next)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color.mmOnboardingBg)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.mmOnboardingAccent)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
            .opacity(appeared ? 1 : 0)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5).delay(0.2)) {
                appeared = true
            }
        }
    }

    // MARK: - Private

    /// 選択中の単位に応じたPickerラベルを返す
    private func pickerLabel(forKg kg: Int) -> String {
        switch selectedUnit {
        case .kg:
            return "\(kg) kg"
        case .lb:
            let lb = Int(round(Double(kg) * 2.20462))
            return "\(lb) lb"
        }
    }
}

#Preview {
    ZStack {
        Color.mmOnboardingBg.ignoresSafeArea()
        WeightInputPage(onNext: {})
    }
}
