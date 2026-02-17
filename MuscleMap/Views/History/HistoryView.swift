import SwiftUI
import SwiftData

// MARK: - 履歴・統計画面

/// 履歴画面の表示モード
enum HistoryViewMode: String, CaseIterable {
    case map = "マップ"
    case calendar = "カレンダー"

    var englishName: String {
        switch self {
        case .map: return "Map"
        case .calendar: return "Calendar"
        }
    }
}

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: HistoryViewModel?
    @State private var selectedCalendarDate: SelectedDate?
    @State private var selectedMuscle: SelectedMuscle?
    @State private var viewMode: HistoryViewMode = .map
    private var localization: LocalizationManager { LocalizationManager.shared }

    /// シート表示用のラッパー（Identifiable対応）
    struct SelectedDate: Identifiable {
        let id = UUID()
        let date: Date
    }

    struct SelectedMuscle: Identifiable {
        let id = UUID()
        let muscle: Muscle
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.mmBgPrimary.ignoresSafeArea()

                if let vm = viewModel {
                    VStack(spacing: 0) {
                        // セグメントコントロール
                        Picker("View Mode", selection: $viewMode) {
                            ForEach(HistoryViewMode.allCases, id: \.self) { mode in
                                Text(localization.currentLanguage == .japanese ? mode.rawValue : mode.englishName)
                                    .tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)
                        .padding(.top, 8)
                        .padding(.bottom, 16)

                        // コンテンツ切り替え
                        switch viewMode {
                        case .map:
                            HistoryMapView(
                                viewModel: vm,
                                onMuscleTap: { muscle in
                                    selectedMuscle = SelectedMuscle(muscle: muscle)
                                }
                            )
                        case .calendar:
                            HistoryCalendarView(
                                viewModel: vm,
                                onDateSelected: { date in
                                    selectedCalendarDate = SelectedDate(date: date)
                                }
                            )
                        }
                    }
                }
            }
            .navigationTitle(L10n.history)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onAppear {
                if viewModel == nil {
                    viewModel = HistoryViewModel(modelContext: modelContext)
                }
                viewModel?.load()
            }
            .sheet(item: $selectedCalendarDate) { selected in
                DayWorkoutDetailView(date: selected.date)
            }
            .sheet(item: $selectedMuscle) { selected in
                if let vm = viewModel {
                    MuscleHistoryDetailSheet(
                        detail: vm.getMuscleHistoryDetail(for: selected.muscle),
                        period: vm.selectedPeriod
                    )
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    HistoryView()
        .modelContainer(for: [WorkoutSession.self, WorkoutSet.self, MuscleStimulation.self], inMemory: true)
}
